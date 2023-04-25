# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Ensure queuing entries are present even if admins skip upgrades.
    class BackfillCiQueuingTables
      class Namespace < ActiveRecord::Base # rubocop:disable Style/Documentation
        self.table_name = 'namespaces'
        self.inheritance_column = :_type_disabled
      end

      class Project < ActiveRecord::Base # rubocop:disable Style/Documentation
        self.table_name = 'projects'

        belongs_to :namespace
        has_one :ci_cd_settings, class_name: 'Gitlab::BackgroundMigration::BackfillCiQueuingTables::ProjectCiCdSetting'

        def group_runners_enabled?
          return false unless ci_cd_settings

          ci_cd_settings.group_runners_enabled?
        end
      end

      class ProjectCiCdSetting < ActiveRecord::Base # rubocop:disable Style/Documentation
        self.table_name = 'project_ci_cd_settings'
      end

      class Taggings < ActiveRecord::Base # rubocop:disable Style/Documentation
        self.table_name = 'taggings'
      end

      module Ci
        class Build < ActiveRecord::Base # rubocop:disable Style/Documentation
          include EachBatch

          self.table_name = 'ci_builds'
          self.inheritance_column = :_type_disabled

          belongs_to :project

          scope :pending, -> do
            where(status: :pending, type: 'Ci::Build', runner_id: nil)
          end

          def self.each_batch(of: 1000, column: :id, order: { runner_id: :asc, id: :asc }, order_hint: nil)
            start = except(:select).select(column).reorder(order)
            start = start.take
            return unless start

            start_id = start[column]
            arel_table = self.arel_table

            1.step do |index|
              start_cond = arel_table[column].gteq(start_id)
              stop = except(:select).select(column).where(start_cond).reorder(order)
              stop = stop.offset(of).limit(1).take
              relation = where(start_cond)

              if stop
                stop_id = stop[column]
                start_id = stop_id
                stop_cond = arel_table[column].lt(stop_id)
                relation = relation.where(stop_cond)
              end

              # Any ORDER BYs are useless for this relation and can lead to less
              # efficient UPDATE queries, hence we get rid of it.
              relation = relation.except(:order)

              # Using unscoped is necessary to prevent leaking the current scope used by
              # ActiveRecord to chain `each_batch` method.
              unscoped { yield relation, index }

              break unless stop
            end
          end

          def tags_ids
            BackfillCiQueuingTables::Taggings
              .where(taggable_id: id, taggable_type: 'CommitStatus')
              .pluck(:tag_id)
          end
        end

        class PendingBuild < ActiveRecord::Base # rubocop:disable Style/Documentation
          self.table_name = 'ci_pending_builds'

          class << self
            def upsert_from_build!(build)
              entry = self.new(args_from_build(build))

              self.upsert(
                entry.attributes.compact,
                returning: %w[build_id],
                unique_by: :build_id)
            end

            def args_from_build(build)
              project = build.project

              {
                build_id: build.id,
                project_id: build.project_id,
                protected: build.protected?,
                namespace_id: project.namespace_id,
                tag_ids: build.tags_ids,
                instance_runners_enabled: project.shared_runners_enabled?,
                namespace_traversal_ids: namespace_traversal_ids(project)
              }
            end

            def namespace_traversal_ids(project)
              if project.group_runners_enabled?
                project.namespace.traversal_ids
              else
                []
              end
            end
          end
        end
      end

      BATCH_SIZE = 100

      def perform(start_id, end_id)
        scope = BackfillCiQueuingTables::Ci::Build.pending.where(id: start_id..end_id)
        pending_builds_query = BackfillCiQueuingTables::Ci::PendingBuild
          .where('ci_builds.id = ci_pending_builds.build_id')
          .select(1)

        scope.each_batch(of: BATCH_SIZE) do |builds|
          builds = builds.where('NOT EXISTS (?)', pending_builds_query)
          builds = builds.includes(:project, project: [:namespace, :ci_cd_settings])

          builds.each do |build|
            BackfillCiQueuingTables::Ci::PendingBuild.upsert_from_build!(build)
          end
        end

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
           arguments)
      end
    end
  end
end
