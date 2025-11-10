# frozen_string_literal: true

# rubocop:disable Database/AvoidScopeTo -- uses partition pruning, doesn't need a specialized index
# rubocop:disable Metrics/ClassLength -- TODO refactor
module Gitlab
  module BackgroundMigration
    class MoveCiBuildsMetadata < BatchedMigrationJob
      feature_category :continuous_integration
      operation_name :create_job_definition_from_builds_metadata

      scope_to ->(relation) { relation.where([@job_arguments].to_h) }

      def self.job_arguments_count
        2
      end

      def perform
        each_sub_batch do |sub_batch|
          # Assumes that all the builds that already have a job definition instance record
          # don't need to have their metadata records be migrated
          available_jobs = job_model
            .where('(p_ci_builds.id, p_ci_builds.partition_id) IN (?)', sub_batch.select(:id, :partition_id))
            .where.not('EXISTS (?)', scoped_definition_instances.select(1))
            .to_a

          available_metadata = metadata_model
            .where([:build_id, :partition_id] => available_jobs.pluck(:id, :partition_id).presence || [[]]).to_a
          metadata_filters = available_metadata.pluck(:build_id, :partition_id)

          update_jobs(metadata_filters)
          update_job_artifacts(metadata_filters)
          setup_definitions(available_jobs, available_metadata)
          copy_environments(sub_batch)
        end
      end

      def setup_definitions(available_jobs, available_metadata)
        tag_names_by_job_id = load_tags_for(available_jobs)
        run_steps_by_job_id = load_run_steps_for(available_jobs)
        metadata_by_job_id = available_metadata.index_by(&:build_id)

        definition_instances_attrs = available_jobs.map do |job|
          metadata = metadata_by_job_id[job.id]
          tag_list = tag_names_by_job_id.fetch(job.id) { [] }
          run_steps = run_steps_by_job_id.fetch(job.id) { [] }

          definition = find_or_create_job_definition_from(job, metadata, tag_list, run_steps)
          job_definition_instance_attrs(job, definition)
        end

        definition_instance_model.insert_all(definition_instances_attrs, unique_by: [:job_id, :partition_id])
      end

      def update_jobs(metadata_filters)
        return if metadata_filters.empty?

        scoped_metadata_sql = <<~SQL.squish
          p_ci_builds.id = p_ci_builds_metadata.build_id
            AND p_ci_builds.partition_id = p_ci_builds_metadata.partition_id
        SQL

        update_sql = <<~SQL
          scoped_user_id = COALESCE(p_ci_builds.scoped_user_id, (p_ci_builds_metadata.config_options->>'scoped_user_id')::bigint),
          timeout = COALESCE(p_ci_builds.timeout, p_ci_builds_metadata.timeout),
          timeout_source = COALESCE(p_ci_builds.timeout_source, p_ci_builds_metadata.timeout_source::smallint),
          exit_code = COALESCE(p_ci_builds.exit_code, p_ci_builds_metadata.exit_code),
          debug_trace_enabled = COALESCE(p_ci_builds.debug_trace_enabled, p_ci_builds_metadata.debug_trace_enabled)
          FROM p_ci_builds_metadata
        SQL

        job_model
          .where(scoped_metadata_sql)
          .where([:id, :partition_id] => metadata_filters)
          .update_all(update_sql)
      end

      def update_job_artifacts(metadata_filters)
        return if metadata_filters.empty?

        scoped_metadata_sql = <<~SQL.squish
          p_ci_job_artifacts.job_id = p_ci_builds_metadata.build_id
            AND p_ci_job_artifacts.partition_id = p_ci_builds_metadata.partition_id
        SQL

        update_sql = <<~SQL.squish
          exposed_as = COALESCE(
            p_ci_job_artifacts.exposed_as,
            p_ci_builds_metadata.config_options->'artifacts'->>'expose_as'
          ),
          exposed_paths = COALESCE(
            p_ci_job_artifacts.exposed_paths,
            CASE
              WHEN p_ci_builds_metadata.config_options->'artifacts'->'paths' IS NOT NULL
              THEN ARRAY(
                SELECT jsonb_array_elements_text(p_ci_builds_metadata.config_options->'artifacts'->'paths')
              )
              ELSE NULL
            END
          )
          FROM p_ci_builds_metadata
        SQL

        job_artifact_model
          .where(file_type: 2) # metadata
          .where(scoped_metadata_sql)
          .where([:job_id, :partition_id] => metadata_filters)
          .update_all(update_sql)
      end

      def job_definition_instance_attrs(job, job_definition)
        {
          job_id: job.id,
          partition_id: job.partition_id,
          job_definition_id: job_definition.id,
          project_id: job.project_id
        }
      end

      def scoped_definition_instances
        definition_instance_model
          .where('p_ci_job_definition_instances.partition_id = p_ci_builds.partition_id')
          .where('p_ci_job_definition_instances.job_id = p_ci_builds.id')
      end

      def definition_model
        @definition_model ||= define_batchable_model(:p_ci_job_definitions, connection: connection, primary_key: :id)
      end

      def definition_instance_model
        @definition_instance_model ||= define_batchable_model(
          :p_ci_job_definition_instances, connection: connection, primary_key: :id)
      end

      def job_taggings_model
        @job_taggings_model ||= define_batchable_model(:p_ci_build_tags, connection: connection, primary_key: :id)
      end

      def job_model
        @job_model ||= define_batchable_model(:p_ci_builds, connection: connection, primary_key: :id).tap do |model|
          model.serialize :options
          model.serialize :yaml_variables
        end
      end

      def metadata_model
        @metadata_model ||= define_batchable_model(:p_ci_builds_metadata, connection: connection, primary_key: :id)
      end

      def job_artifact_model
        @job_artifact_model ||= define_batchable_model(:p_ci_job_artifacts, connection: connection, primary_key: :id)
      end

      def find_or_create_job_definition_from(job, metadata, tag_list, run_steps)
        config = generate_definition_config(job, metadata, tag_list, run_steps)
        checksum = compute_checksum(config)

        attrs = {
          project_id: job.project_id,
          partition_id: job.partition_id,
          config: config,
          checksum: checksum,
          created_at: Time.current,
          interruptible: config.fetch(:interruptible, false)
        }

        find_or_create_definition_by(attrs)
      end

      def generate_definition_config(job, metadata, tag_list, run_steps)
        config = {}
        config[:options] = metadata&.config_options || job.options
        config[:yaml_variables] = metadata&.config_variables || job.yaml_variables.to_h.transform_values(&:to_s)

        if metadata
          config[:id_tokens] = metadata.id_tokens if metadata.id_tokens.present?
          config[:secrets] = metadata.secrets if metadata.secrets.present?
          config[:interruptible] = metadata.interruptible unless metadata.interruptible.nil?
        end

        config[:tag_list] = tag_list if tag_list.any?
        config[:run_steps] = run_steps if run_steps.any?
        config
      end

      def compute_checksum(config)
        Digest::SHA256.hexdigest(Gitlab::Json.dump(config))
      end

      def find_or_create_definition_by(attrs)
        unique_attr_names = %i[project_id checksum partition_id]
        record = definition_model.find_by(attrs.slice(*unique_attr_names))
        return record if record.present?

        definition_model.insert_all([attrs], unique_by: unique_attr_names)
        definition_model.find_by!(attrs.slice(*unique_attr_names))
      end

      def load_tags_for(job_records)
        filters = job_records.pluck(:id, :partition_id)
        return {} if filters.empty?

        job_taggings_model
          .where([:build_id, :partition_id] => filters)
          .joins('INNER JOIN tags ON tags.id = p_ci_build_tags.tag_id')
          .group(:build_id)
          .pluck(:build_id, Arel.sql('COALESCE(array_agg(tags.name ORDER BY tags.name), ARRAY[]::text[])'))
          .to_h
      end

      def load_run_steps_for(job_records)
        filters = job_records.pluck(:id, :partition_id)
        return {} if filters.empty?

        join_sql = <<~SQL.squish
          INNER JOIN p_ci_builds_execution_configs
            ON p_ci_builds.execution_config_id = p_ci_builds_execution_configs.id
            AND p_ci_builds.partition_id = p_ci_builds_execution_configs.partition_id
        SQL

        job_model
          .where([:id, :partition_id] => filters)
          .joins(join_sql)
          .pluck(Arel.sql('p_ci_builds.id'), Arel.sql('p_ci_builds_execution_configs.run_steps'))
          .to_h
      end

      def copy_environments(jobs_batch)
        metadata_records = metadata_model
          .where("(p_ci_builds_metadata.build_id, p_ci_builds_metadata.partition_id) IN (?)",
            jobs_batch.select(:id, :partition_id))

        job_environment_attributes = fetch_environment_attributes(metadata_records)
        return if job_environment_attributes.empty?

        bulk_insert_job_environments(job_environment_attributes)
      end

      def fetch_environment_attributes(relation)
        join_sql = <<~SQL.squish
          INNER JOIN p_ci_builds
            ON p_ci_builds.partition_id = p_ci_builds_metadata.partition_id
            AND p_ci_builds.id = p_ci_builds_metadata.build_id
        SQL

        select_sql = <<~SQL.squish
          p_ci_builds_metadata.project_id,
          p_ci_builds_metadata.build_id AS ci_job_id,
          p_ci_builds_metadata.expanded_environment_name,
          p_ci_builds_metadata.config_options -> 'environment' AS options,
          p_ci_builds.commit_id AS ci_pipeline_id
        SQL

        relation
          .where.not(expanded_environment_name: nil)
          .joins(join_sql)
          .select(select_sql)
          .map { |metadata| extract_environment_attributes(metadata) }
      end

      def extract_environment_attributes(metadata)
        attributes = metadata.attributes.slice(
          'project_id', 'ci_job_id', 'ci_pipeline_id', 'expanded_environment_name', 'options'
        )

        options = attributes['options'] || {}
        kubernetes_options = options['kubernetes']&.slice('namespace')
        options = options.slice('action', 'deployment_tier')
        options['kubernetes'] = kubernetes_options if kubernetes_options.present?

        attributes['options'] = options.to_json
        attributes
      end

      def bulk_insert_job_environments(attributes)
        values_list = Arel::Nodes::ValuesList.new(attributes.map(&:values)).to_sql
        command = <<~SQL.squish
          WITH ci_job_attributes (project_id, ci_job_id, ci_pipeline_id, expanded_environment_name, options) AS (#{values_list})
          INSERT INTO job_environments (project_id, environment_id, ci_job_id, ci_pipeline_id, deployment_id, expanded_environment_name, options)
          SELECT
            ci_job_attributes.project_id,
            environments.id,
            ci_job_id,
            ci_pipeline_id,
            deployments.id,
            expanded_environment_name,
            options::jsonb
          FROM
            ci_job_attributes
            INNER JOIN environments ON environments.project_id = ci_job_attributes.project_id
              AND environments.name = ci_job_attributes.expanded_environment_name
            LEFT JOIN deployments ON deployments.deployable_id = ci_job_attributes.ci_job_id
              AND deployments.deployable_type = 'CommitStatus'
            ON CONFLICT DO NOTHING;
        SQL

        ApplicationRecord.connection.execute(command)
      end
    end
  end
end
# rubocop:enable Database/AvoidScopeTo
# rubocop:enable Metrics/ClassLength
