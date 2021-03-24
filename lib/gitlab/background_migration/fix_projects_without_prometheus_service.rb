# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration creates missing services records
    # for the projects within the given range of ids
    class FixProjectsWithoutPrometheusService
      # There is important inconsistency between single query timeout 15s and background migration worker minimum lease 2 minutes
      # to address that scheduled ids range (for minimum 2 minutes processing) should be inserted in smaller portions to fit under 15s limit.
      # https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/9064#note_279857215
      MAX_BATCH_SIZE = 1_000
      DEFAULTS = {
        'active' => true,
        'properties' => "'{}'",
        'type' => "'PrometheusService'",
        'template' => false,
        'push_events' => true,
        'issues_events' => true,
        'merge_requests_events' => true,
        'tag_push_events' => true,
        'note_events' => true,
        'category' => "'monitoring'",
        'default' => false,
        'wiki_page_events' => true,
        'pipeline_events' => true,
        'confidential_issues_events' => true,
        'commit_events' => true,
        'job_events' => true,
        'confidential_note_events' => true
      }.freeze

      module Migratable
        module Applications
          # Migration model namespace isolated from application code.
          class Prometheus
            def self.statuses
              {
                errored: -1,
                installed: 3,
                updated: 5
              }
            end
          end
        end

        # Migration model namespace isolated from application code.
        class Cluster < ActiveRecord::Base
          self.table_name = 'clusters'

          enum cluster_type: {
            instance_type: 1,
            group_type: 2
          }

          def self.has_prometheus_application?
            joins("INNER JOIN clusters_applications_prometheus ON clusters_applications_prometheus.cluster_id = clusters.id
                   AND clusters_applications_prometheus.status IN (#{Applications::Prometheus.statuses[:installed]}, #{Applications::Prometheus.statuses[:updated]})").exists?
          end
        end

        # Migration model namespace isolated from application code.
        class PrometheusService < ActiveRecord::Base
          self.inheritance_column = :_type_disabled
          self.table_name = 'services'
          default_scope { where(type: type) } # rubocop:disable Cop/DefaultScope

          def self.type
            'PrometheusService'
          end

          def self.template
            find_by(template: true)
          end

          def self.values
            (template&.attributes_for_insert || DEFAULTS).merge('template' => false, 'active' => true).values
          end

          def attributes_for_insert
            slice(DEFAULTS.keys).transform_values do |v|
              v.is_a?(String) ? "'#{v}'" : v
            end
          end
        end

        # Migration model namespace isolated from application code.
        class Project < ActiveRecord::Base
          self.table_name = 'projects'

          scope :select_for_insert, -> {
            select('id')
              .select(PrometheusService.values.join(','))
              .select("TIMEZONE('UTC', NOW()) as created_at", "TIMEZONE('UTC', NOW()) as updated_at")
          }

          scope :with_prometheus_services, ->(from_id, to_id) {
            joins("LEFT JOIN services ON services.project_id = projects.id AND services.project_id BETWEEN #{Integer(from_id)} AND #{Integer(to_id)}
                    AND services.type = '#{PrometheusService.type}'")
          }

          scope :with_group_prometheus_installed, -> {
            joins("INNER JOIN cluster_groups ON cluster_groups.group_id = projects.namespace_id")
              .joins("INNER JOIN clusters_applications_prometheus ON clusters_applications_prometheus.cluster_id = cluster_groups.cluster_id
                      AND clusters_applications_prometheus.status IN (#{Applications::Prometheus.statuses[:installed]}, #{Applications::Prometheus.statuses[:updated]})")
          }
        end
      end

      def perform(from_id, to_id)
        (from_id..to_id).each_slice(MAX_BATCH_SIZE) do |batch|
          process_batch(batch.first, batch.last)
        end
      end

      private

      def process_batch(from_id, to_id)
        update_inconsistent(from_id, to_id)
        create_missing(from_id, to_id)
      end

      def create_missing(from_id, to_id)
        result = ActiveRecord::Base.connection.select_one(create_sql(from_id, to_id))
        return unless result

        logger.info(message: "#{self.class}: created missing services for #{result['number_of_created_records']} projects in id=#{from_id}...#{to_id}")
      end

      def update_inconsistent(from_id, to_id)
        result = ActiveRecord::Base.connection.select_one(update_sql(from_id, to_id))
        return unless result

        logger.info(message: "#{self.class}: updated inconsistent services for #{result['number_of_updated_records']} projects in id=#{from_id}...#{to_id}")
      end

      # there is no uniq constraint on project_id and type pair, which prevents us from using ON CONFLICT
      def create_sql(from_id, to_id)
        <<~SQL
          WITH created_records AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
            INSERT INTO services (project_id, #{DEFAULTS.keys.map { |key| %("#{key}")}.join(',')}, created_at, updated_at)
            #{select_insert_values_sql(from_id, to_id)}
            RETURNING *
          )
          SELECT COUNT(*) as number_of_created_records
          FROM created_records
        SQL
      end

      # there is no uniq constraint on project_id and type pair, which prevents us from using ON CONFLICT
      def update_sql(from_id, to_id)
        <<~SQL
          WITH updated_records AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
            UPDATE services SET active = TRUE
            WHERE services.project_id BETWEEN #{Integer(from_id)} AND #{Integer(to_id)} AND services.properties = '{}' AND services.type = '#{Migratable::PrometheusService.type}'
            AND #{group_cluster_condition(from_id, to_id)} AND services.active = FALSE
            RETURNING *
          )
          SELECT COUNT(*) as number_of_updated_records
          FROM updated_records
        SQL
      end

      def group_cluster_condition(from_id, to_id)
        return '1 = 1' if migrate_instance_cluster?

        <<~SQL
          EXISTS (
            #{Migratable::Project.select(1).with_group_prometheus_installed.where("projects.id BETWEEN ? AND ?", Integer(from_id), Integer(to_id)).to_sql}
          )
        SQL
      end

      def select_insert_values_sql(from_id, to_id)
        scope = Migratable::Project
                  .select_for_insert
                  .with_prometheus_services(from_id, to_id)
                  .where("projects.id BETWEEN ? AND ? AND services.id IS NULL", Integer(from_id), Integer(to_id))

        return scope.to_sql if migrate_instance_cluster?

        scope.with_group_prometheus_installed.to_sql
      end

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end

      def migrate_instance_cluster?
        if instance_variable_defined?('@migrate_instance_cluster')
          @migrate_instance_cluster
        else
          @migrate_instance_cluster = Migratable::Cluster.instance_type.has_prometheus_application?
        end
      end
    end
  end
end
