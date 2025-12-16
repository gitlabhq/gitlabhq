# frozen_string_literal: true

# rubocop:disable Database/AvoidScopeTo -- uses partition pruning, doesn't need a specialized index
# rubocop:disable Metrics/ClassLength -- TODO refactor?
#
# ==============================================================================
#
# This migration copies data from existing CI build tables into a more
# normalized structure to improve database storage efficiency. There is no data
# removal happening here, that will happen in a later iteration after we confirm
# that the migration completed successfully.
# See this blueprint for more details:
# https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ci_data_decay/reduce_data_growth_rate/
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214376
# for user configuration options.
#
# Migration Overview:
# -------------------
#
# 1. Job configuration data gets copied to `p_ci_job_definitions`
#    From `p_ci_builds_metadata` we copy:
#    - config_options
#    - config_variables
#    - id_tokens
#    - secrets
#    - interruptible
#
#    From `p_ci_builds` we copy (fallback for really old data, jobs created > 6 years ago):
#    - options
#    - yaml_variables
#
# 2. Job `tags` also get copied to `p_ci_job_definitions`
#    We get the tag ids from the `p_ci_build_tags` and construct the `tag_list`
#    from `tags` and include it in the job definition.
#
# 3. Execution steps get copied to `p_ci_job_definitions`
#    From `p_ci_build_execution_configs` we move the `run_steps` to the definitions table.
#
# 4. Jobs - definition relationship is stored in `p_ci_job_definition_instances`
#    In the current setup we have one `p_ci_builds_metadata` for each `p_ci_builds`,
#    but now a job definition has many jobs and we're storing this relation in
#    a new table called `p_ci_job_definition_instances`.
#
# 5. Job user data is kept in `p_ci_builds`
#    Data that was kept in `p_ci_builds_metadata` but is supposed to be long lived,
#    i.e. shown in the UI for the users, is moved to the `p_ci_builds` table.
#    These are the columns that are copied over:
#    - scoped_user_id (extracted from the config_options)
#    - timeout
#    - timeout_source
#    - exit_code
#    - debug_trace_enabled
#
# 6. Job artifact configuration gets moved to `p_ci_job_artifacts`
#    From `p_ci_builds_metadata` we extract this data from `config_options`:
#    - exposed_as
#    - exposed_paths
#
# 7. Environment settings are moved to `job_environments`:
#    We used to store them `p_ci_builds_metadata` but we now have new tables for these too:
#    - expanded_environment_name
#    - environment options
#
# ==============================================================================
#
module Gitlab
  module BackgroundMigration
    class MoveCiBuildsMetadata < BatchedMigrationJob
      # Each job definition is unique by these attributes.
      DEFS_UNIQ_ATTRS = [:project_id, :partition_id, :checksum].freeze

      feature_category :continuous_integration
      operation_name :create_job_definition_from_builds_metadata

      # We're enqueuing a background migration for each physical partition with job args
      # as partition_id and its values. This is then converted to something like
      # `where partition_id = 100` which helps the database performance with partitioning pruning.
      scope_to ->(relation) { relation.where([@job_arguments].to_h) }

      def self.job_arguments_count
        2
      end

      # We know that there are installations with years of data that they might not want to migrate
      # so we provide a few switches here to skip old data.
      # The background migrations are executed in Sidekiq, so these should be set as ENV variables
      # on nodes that execute the Sidekiq jobs and Sidekiq must be restarted after they are changed.
      # There should be a line in `log/application_json.log` showing what values are used.
      class EnvConfig
        attr_reader :migration_cutoff, :processing_data_cutoff

        def initialize
          @migration_cutoff = fetch_env_timestamp('GITLAB_DB_CI_JOBS_MIGRATION_CUTOFF')
          @processing_data_cutoff = fetch_env_timestamp('GITLAB_DB_CI_JOBS_PROCESSING_DATA_CUTOFF')
          @processing_data_cutoff ||= processing_data_cutoff_from_db&.seconds&.ago
          @processing_data_cutoff ||= @migration_cutoff
        end

        private

        def fetch_env_timestamp(key)
          value = ENV[key]
          return unless value

          value = ChronicDuration.parse(value)
          return unless value

          value.seconds.ago
        end

        # https://docs.gitlab.com/administration/settings/continuous_integration/#archive-pipelines
        def processing_data_cutoff_from_db
          ApplicationRecord.connection.select_value(<<~SQL)
            SELECT archive_builds_in_seconds FROM application_settings ORDER BY id desc LIMIT 1;
          SQL
        end
      end

      # The migration iterates over an entire `p_ci_builds` partition and with this class
      # we're applying the user defined cutoff policies so that only the relevant data
      # is copied.
      class JobsFilter
        attr_reader :migration, :jobs_batch

        def initialize(migration, jobs_batch, config)
          @migration = migration
          @jobs_batch = jobs_batch
          @config = config
          @jobs_cache = {}
        end

        def job_ids_filter
          @job_ids_filter ||= load_jobs_created_after(migration_cutoff).pluck(:id, :partition_id)
        end

        def jobs_for_definitions
          @jobs_for_definitions ||= load_jobs_created_after(processing_data_cutoff)
        end

        def jobs_for_environments
          return jobs_batch unless migration_cutoff.present?

          jobs_batch.where(created_at: migration_cutoff...)
        end

        private

        delegate :migration_cutoff, :processing_data_cutoff, to: :@config

        # This is a cache to reduce the number of queries since we need to load this data
        # to create definitions, update jobs, and update artifacts.
        # If the users have the same cutoff for processing data and all data, we can remove a query
        # per batch with this cache.
        def load_jobs_created_after(timestamp)
          @jobs_cache.fetch(timestamp) do |key|
            @jobs_cache[key] = jobs_without_definitions_created_after(timestamp).to_a
          end
        end

        def jobs_without_definitions_created_after(timestamp)
          if timestamp
            jobs_without_definitions.where(created_at: timestamp...)
          else
            jobs_without_definitions
          end
        end

        # New jobs get created in the new format, so we assume that all the jobs that
        # already are assigned to a job definition don't need to be migrated.
        def jobs_without_definitions
          migration.job_model
            .where('(p_ci_builds.id, p_ci_builds.partition_id) IN (?)', jobs_batch.select(:id, :partition_id))
            .where.not('EXISTS (?)', scoped_definition_instances.select(1))
        end

        def scoped_definition_instances
          migration.definition_instance_model
            .where('p_ci_job_definition_instances.partition_id = p_ci_builds.partition_id')
            .where('p_ci_job_definition_instances.job_id = p_ci_builds.id')
        end
      end

      # Not all data resides in the builds_metadata table, so we need to query
      # other tables too. Since we can't use application code here, we're building
      # a similar abstraction to the ActiveRecord preloader to load connected data.
      # It returns a new jobs collection with tags, execution steps, and the metadata record.
      class JobsPreloader
        attr_reader :jobs

        def initialize(migration, jobs)
          @migration = migration
          @jobs = jobs
        end

        def execute
          jobs.map do |job|
            JobPresenter.new(
              job,
              metadata: metadata_records[job.id],
              tag_list: tag_records[job.id],
              run_steps: run_steps_records[job.id]
            )
          end
        end

        private

        delegate :metadata_model, :job_taggings_model, :job_model, to: :@migration

        def filters
          @filters ||= jobs.pluck(:id, :partition_id).presence || [[]]
        end

        def metadata_records
          @metadata_records ||= metadata_model
            .where([:build_id, :partition_id] => filters)
            .index_by(&:build_id)
        end

        def tag_records
          @tag_records ||= job_taggings_model
            .where([:build_id, :partition_id] => filters)
            .joins('INNER JOIN tags ON tags.id = p_ci_build_tags.tag_id')
            .group(:build_id)
            .pluck(:build_id, Arel.sql('COALESCE(array_agg(tags.name ORDER BY tags.name), ARRAY[]::text[])'))
            .to_h
        end

        def run_steps_records
          @run_steps_records ||= job_model
            .where([:id, :partition_id] => filters)
            .joins(run_steps_join_sql)
            .pluck(Arel.sql('p_ci_builds.id'), Arel.sql('p_ci_builds_execution_configs.run_steps'))
            .to_h
        end

        def run_steps_join_sql
          <<~SQL.squish
            INNER JOIN p_ci_builds_execution_configs
              ON p_ci_builds.execution_config_id = p_ci_builds_execution_configs.id
              AND p_ci_builds.partition_id = p_ci_builds_execution_configs.partition_id
          SQL
        end
      end

      # We're extending the job object to store the connected data in memory.
      class JobPresenter < SimpleDelegator
        attr_reader :metadata, :tag_list, :run_steps
        attr_accessor :job_definition

        def initialize(job, metadata:, tag_list:, run_steps:)
          @job = job
          @metadata = metadata
          @tag_list = tag_list
          @run_steps = run_steps

          super(job)
        end

        def definition_config
          config = {}

          # We also handle really old jobs here that were created before we added the metadata table/
          config[:options] = metadata&.config_options || options
          config[:yaml_variables] = metadata&.config_variables.presence || parsed_variables

          config.merge!(metadata_only_attrs) if metadata

          config[:tag_list] = tag_list if tag_list.present?
          config[:run_steps] = run_steps if run_steps.present?
          config
        end

        private

        # These attributes are stored only in the metadata record, but not all job records
        # might have one since we started creating them ~ 6 years ago.
        def metadata_only_attrs
          config = {}
          config[:id_tokens] = metadata.id_tokens if metadata.id_tokens.present?
          config[:secrets] = metadata.secrets if metadata.secrets.present?
          config[:interruptible] = metadata.interruptible unless metadata.interruptible.nil?
          config
        end

        # We must ensure that the variables use the correct format since they were stored as
        # serialized YAML and that could store Symbols.
        def parsed_variables
          (yaml_variables || []).map do |var|
            var.deep_stringify_keys!
            var['key'] = var['key'].to_s
            var['value'] = var['value'].to_s
            var
          end
        end
      end

      # This is the main migration point for the definitions.
      # For each jobs it builds a new definition object in memory and passes them
      # to the `BulkJobDefinitionsCreator` to transform them in persisted objects.
      # We use `global_identifier` to correlate between the in memory objects and
      # the database objects because each definition is unique by
      # `project_id, partition_id, checksum` attributes, not only by `checksum`.
      # After the definitions are persisted we also bulk inset the glue records
      # in their separate table.
      class JobsDefinitionsAssigner
        attr_reader :jobs

        delegate :definition_model, :definition_instance_model, to: :@migration

        def initialize(migration, jobs)
          @migration = migration
          @jobs = jobs
        end

        def execute
          definitions = jobs.map { |job| job.job_definition = definition_model.initialize_from(job) }
          persisted_definitions = bulk_persist_definitions(definitions)

          definition_instances_attrs = jobs.map do |job|
            job_definition = persisted_definitions.fetch(job.job_definition.global_identifier)

            job_definition_instance_attrs_for(job, job_definition)
          end

          definition_instance_model.insert_all(definition_instances_attrs, unique_by: [:job_id, :partition_id])
        end

        private

        def bulk_persist_definitions(defs)
          BulkJobDefinitionsCreator
            .new(@migration, defs)
            .execute
            .index_by(&:global_identifier)
        end

        def job_definition_instance_attrs_for(job, job_definition)
          {
            job_id: job.id,
            partition_id: job.partition_id,
            job_definition_id: job_definition.id,
            project_id: job.project_id
          }
        end
      end

      # This class is handed an array of not persisted job definitions and returns
      # an unique array of persisted definitions containing only the required
      # attributes for the migration.
      class BulkJobDefinitionsCreator
        attr_reader :job_definitions

        delegate :definition_model, to: :@migration

        def initialize(migration, definitions)
          @migration = migration
          @job_definitions = definitions.uniq(&:global_identifier)
        end

        def execute
          return [] if job_definitions.empty?

          existing_definitions = fetch_records_for(job_definitions)

          existing_definitions_by_attrs = existing_definitions.group_by(&:global_identifier)
          missing_definitions = job_definitions.reject do |d|
            existing_definitions_by_attrs[d.global_identifier]
          end

          return existing_definitions if missing_definitions.empty?

          insert_missing(missing_definitions)

          existing_definitions + fetch_records_for(missing_definitions)
        end

        private

        def fetch_records_for(definitions)
          definition_model
            .select(:id, *DEFS_UNIQ_ATTRS)
            .where(DEFS_UNIQ_ATTRS => definitions.pluck(*DEFS_UNIQ_ATTRS))
            .to_a
        end

        def insert_missing(definitions)
          attributes = definitions.map { |d| d.attributes.compact }

          definition_model.insert_all(attributes, unique_by: DEFS_UNIQ_ATTRS)
        end
      end

      def perform
        config = EnvConfig.new

        Gitlab::AppJsonLogger.info(message: "Migration cutoff config", class: self.class.name.to_s,
          migration_cutoff: config.migration_cutoff, processing_data_cutoff: config.processing_data_cutoff)

        each_sub_batch do |sub_batch|
          context = JobsFilter.new(self, sub_batch, config)

          update_jobs(context.job_ids_filter)
          update_job_artifacts(context.job_ids_filter)
          setup_definitions(context.jobs_for_definitions)
          copy_environments(context.jobs_for_environments)
        end
      end

      def setup_definitions(available_jobs)
        jobs = JobsPreloader.new(self, available_jobs).execute
        JobsDefinitionsAssigner.new(self, jobs).execute
      end

      # This copies the data from `p_ci_builds_metadata` to `p_ci_builds` without
      # overriding it if it already exists in the destination table.
      # This is usually showed in the job's log page.
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

      # This copies the data from `p_ci_builds_metadata` to `p_ci_job_artifacts` without overriding it.
      # This data is shown in in the MR widget as exposed artifacts.
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

      # Dynamic ActiveRecord models to interact with the database tables.
      def definition_model
        @definition_model ||= ci_model(:p_ci_job_definitions).tap do |klass|
          # Define instance methods, like `global_identifier` that returns an
          # array containing the unique attributes values.
          klass.class_eval do
            def global_identifier
              attributes.values_at(*DEFS_UNIQ_ATTRS.map(&:to_s))
            end
          end

          # Define class methods
          klass.instance_eval do
            # Similar to the fabricate method in app/models/ci/job_definition.rb#L44-74
            def initialize_from(job)
              config = job.definition_config

              attrs = {
                project_id: job.project_id,
                partition_id: job.partition_id,
                config: config,
                checksum: compute_checksum(config),
                created_at: Time.current,
                interruptible: config.fetch(:interruptible, false)
              }

              new(attrs)
            end

            def compute_checksum(config)
              Digest::SHA256.hexdigest(Gitlab::Json.dump(config))
            end
          end
        end
      end

      def definition_instance_model
        @definition_instance_model ||= ci_model(:p_ci_job_definition_instances, primary_key: :job_id)
      end

      def job_taggings_model
        @job_taggings_model ||= ci_model(:p_ci_build_tags)
      end

      def job_model
        @job_model ||= ci_model(:p_ci_builds).tap do |model|
          model.serialize :options
          model.serialize :yaml_variables
        end
      end

      def metadata_model
        @metadata_model ||= ci_model(:p_ci_builds_metadata)
      end

      def job_artifact_model
        @job_artifact_model ||= ci_model(:p_ci_job_artifacts)
      end

      def ci_model(table_name, primary_key: :id)
        define_batchable_model(table_name, connection: connection, primary_key: primary_key)
      end

      # We used to store the job environments data in the `p_ci_builds_metadata` table,
      # but now this is kept in a new table in the `main` database.
      #
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
