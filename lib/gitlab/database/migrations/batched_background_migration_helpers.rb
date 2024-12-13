# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      # BatchedBackgroundMigrations are a new approach to scheduling and executing background migrations, which uses
      # persistent state in the database to track each migration. This avoids having to batch over an entire table and
      # schedule a large number of sidekiq jobs upfront. It also provides for more flexibility as the migration runs,
      # as it can be paused and restarted, and have configuration values like the batch size updated dynamically as the
      # migration runs.
      #
      # For now, these migrations are not considered ready for general use, for more information see the tracking epic:
      # https://gitlab.com/groups/gitlab-org/-/epics/6751
      module BatchedBackgroundMigrationHelpers
        NonExistentMigrationError = Class.new(StandardError)
        BATCH_SIZE = 1_000 # Number of rows to process per job
        SUB_BATCH_SIZE = 100 # Number of rows to process per sub-batch
        BATCH_CLASS_NAME = 'PrimaryKeyBatchingStrategy' # Default batch class for batched migrations
        BATCH_MIN_VALUE = 1 # Default minimum value for batched migrations
        BATCH_MIN_DELAY = 2.minutes.freeze # Minimum delay between batched migrations

        ENFORCE_EARLY_FINALIZATION_FROM_VERSION = '20240905124117'
        EARLY_FINALIZATION_ERROR = <<-MESSAGE.squeeze(' ').strip
          Batched migration should be finalized only after at-least one required stop from queuing it.
          This is to ensure that we are not breaking the upgrades for self-managed instances.

          For more info visit: https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#finalize-a-batched-background-migration
        MESSAGE

        # Creates a batched background migration for the given table. A batched migration runs one job
        # at a time, computing the bounds of the next batch based on the current migration settings and the previous
        # batch bounds. Each job's execution status is tracked in the database as the migration runs. The given job
        # class must be present in the Gitlab::BackgroundMigration module, and the batch class (if specified) must be
        # present in the Gitlab::BackgroundMigration::BatchingStrategies module.
        #
        # If migration with same job_class_name, table_name, column_name, and job_arguments already exists, this helper
        # will log an warning and not create a new one.
        #
        # job_class_name - The background migration job class as a string
        # batch_table_name - The name of the table the migration will batch over
        # batch_column_name - The name of the column the migration will batch over
        # job_arguments - Extra arguments to pass to the job instance when the migration runs
        # job_interval - The pause interval between each job's execution, minimum of 2 minutes
        # batch_min_value - The value in the column the batching will begin at
        # batch_max_value - The value in the column the batching will end at, defaults to `SELECT MAX(batch_column)`
        # batch_class_name - The name of the class that will be called to find the range of each next batch
        # batch_size - The maximum number of rows per job
        # sub_batch_size - The maximum number of rows processed per "iteration" within the job
        #
        # *Returns the created BatchedMigration record*
        #
        # Example:
        #
        #     queue_batched_background_migration(
        #       'CopyColumnUsingBackgroundMigrationJob',
        #       :events,
        #       :id,
        #       job_interval: 2.minutes,
        #       other_job_arguments: ['column1', 'column2'])
        #
        # Where the the background migration exists:
        #
        #     class Gitlab::BackgroundMigration::CopyColumnUsingBackgroundMigrationJob
        #       def perform(start_id, end_id, batch_table, batch_column, sub_batch_size, *other_args)
        #         # do something
        #       end
        #     end
        def queue_batched_background_migration( # rubocop:disable Metrics/ParameterLists
          job_class_name,
          batch_table_name,
          batch_column_name,
          *job_arguments,
          job_interval:,
          batch_min_value: BATCH_MIN_VALUE,
          batch_max_value: nil,
          batch_class_name: BATCH_CLASS_NAME,
          batch_size: BATCH_SIZE,
          pause_ms: 100,
          max_batch_size: nil,
          sub_batch_size: SUB_BATCH_SIZE,
          gitlab_schema: nil
        )
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_dml_mode!

          gitlab_schema ||= gitlab_schema_from_context
          # Version of the migration that queued the BBM, this is used to establish dependencies
          queued_migration_version = version

          Gitlab::Database::BackgroundMigration::BatchedMigration.reset_column_information

          if Gitlab::Database::BackgroundMigration::BatchedMigration.for_configuration(gitlab_schema, job_class_name, batch_table_name, batch_column_name, job_arguments, include_compatible: true).exists?
            Gitlab::AppLogger.warn "Batched background migration not enqueued because it already exists: " \
              "job_class_name: #{job_class_name}, table_name: #{batch_table_name}, column_name: #{batch_column_name}, " \
              "job_arguments: #{job_arguments.inspect}"
            return
          end

          job_interval = BATCH_MIN_DELAY if job_interval < BATCH_MIN_DELAY

          batch_max_value ||= connection.select_value(<<~SQL)
            SELECT MAX(#{connection.quote_column_name(batch_column_name)})
            FROM #{connection.quote_table_name(batch_table_name)}
          SQL

          status_event = batch_max_value.nil? ? :finish : :execute
          batch_max_value ||= batch_min_value

          migration = Gitlab::Database::BackgroundMigration::BatchedMigration.new(
            job_class_name: job_class_name,
            table_name: batch_table_name,
            column_name: batch_column_name,
            job_arguments: job_arguments,
            interval: job_interval,
            pause_ms: pause_ms,
            min_value: batch_min_value,
            max_value: batch_max_value,
            batch_class_name: batch_class_name,
            batch_size: batch_size,
            sub_batch_size: sub_batch_size,
            status_event: status_event
          )

          if migration.job_class.respond_to?(:job_arguments_count) && migration.job_class.job_arguments_count != job_arguments.count
            raise "Wrong number of job arguments for #{migration.job_class_name} " \
              "(given #{job_arguments.count}, expected #{migration.job_class.job_arguments_count})"
          end

          assign_attributes_safely(
            migration,
            max_batch_size,
            batch_table_name,
            gitlab_schema,
            queued_migration_version
          )

          migration.save!
          migration
        end

        def finalize_batched_background_migration(job_class_name:, table_name:, column_name:, job_arguments:)
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_dml_mode!

          if transaction_open?
            raise 'The `finalize_batched_background_migration` cannot be run inside a transaction. ' \
              'You can disable transactions by calling `disable_ddl_transaction!` in the body of ' \
              'your migration class.'
          end

          Gitlab::Database::BackgroundMigration::BatchedMigration.reset_column_information

          migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_for_configuration(
            gitlab_schema_from_context, job_class_name, table_name, column_name, job_arguments,
            include_compatible: true
          )

          raise 'Could not find batched background migration' if migration.nil?

          with_restored_connection_stack do |restored_connection|
            Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
              Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.finalize(
                job_class_name, table_name,
                column_name, job_arguments,
                connection: restored_connection)
            end
          end
        end

        # Deletes batched background migration for the given configuration.
        #
        # job_class_name - The background migration job class as a string
        # table_name - The name of the table the migration iterates over
        # column_name - The name of the column the migration will batch over
        # job_arguments - Migration arguments
        #
        # Example:
        #
        #     delete_batched_background_migration(
        #       'CopyColumnUsingBackgroundMigrationJob',
        #       :events,
        #       :id,
        #       ['column1', 'column2'])
        def delete_batched_background_migration(job_class_name, table_name, column_name, job_arguments)
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_dml_mode!

          Gitlab::Database::BackgroundMigration::BatchedMigration.reset_column_information

          Gitlab::Database::BackgroundMigration::BatchedMigration
            .for_configuration(
              gitlab_schema_from_context, job_class_name, table_name, column_name, job_arguments,
              include_compatible: true
            ).delete_all
        end

        def gitlab_schema_from_context
          if respond_to?(:allowed_gitlab_schemas) # Gitlab::Database::Migration::V2_0
            Array(allowed_gitlab_schemas).first
          else                                    # Gitlab::Database::Migration::V1_0
            :gitlab_main
          end
        end

        def ensure_batched_background_migration_is_finished(
          job_class_name:,
          table_name:,
          column_name:,
          job_arguments:,
          finalize: true,
          skip_early_finalization_validation: false
        )
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_dml_mode!

          if transaction_open?
            raise 'The `ensure_batched_background_migration_is_finished` cannot be run inside a transaction. ' \
              'You can disable transactions by calling `disable_ddl_transaction!` in the body of ' \
              'your migration class.'
          end

          Gitlab::Database::BackgroundMigration::BatchedMigration.reset_column_information
          migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_for_configuration(
            gitlab_schema_from_context,
            job_class_name, table_name, column_name, job_arguments,
            include_compatible: true
          )

          configuration = {
            job_class_name: job_class_name,
            table_name: table_name,
            column_name: column_name,
            job_arguments: job_arguments
          }

          if ENV['DBLAB_ENVIRONMENT'] && migration.nil?
            raise NonExistentMigrationError, 'called ensure_batched_background_migration_is_finished with non-existent migration name'
          end

          return Gitlab::AppLogger.warn "Could not find batched background migration for the given configuration: #{configuration}" if migration.nil?

          if migration.respond_to?(:queued_migration_version) && !skip_early_finalization_validation
            prevent_early_finalization!(migration.queued_migration_version, version)
          end

          return if migration.finalized?

          if migration.finished?
            migration.confirm_finalize!
            return
          end

          finalize_batched_background_migration(job_class_name: job_class_name, table_name: table_name, column_name: column_name, job_arguments: job_arguments) if finalize

          if migration.reload.finished? # rubocop:disable Cop/ActiveRecordAssociationReload -- TODO: ensure that we have latest version of the batched migration
            migration.confirm_finalize!
            return
          end

          raise "Expected batched background migration for the given configuration to be marked as 'finished', " \
            "but it is '#{migration.status_name}':" \
            "\t#{configuration}" \
            "\n\n" \
            "Finalize it manually by running the following command in a `bash` or `sh` shell:" \
            "\n\n" \
            "\t#{migration.finalize_command}" \
            "\n\n" \
            "For more information, check the documentation" \
            "\n\n" \
            "\thttps://docs.gitlab.com/ee/update/background_migrations.html#database-migrations-failing-because-of-batched-background-migration-not-finished"
        end

        private

        # Below `BatchedMigration` attributes were introduced after the
        # initial `batched_background_migrations` table was created, so any
        # migrations that ran relying on initial table schema would not know
        # about columns introduced later on because this model is not
        # isolated in migrations, which is why we need to check for existence
        # of these columns first.
        def assign_attributes_safely(migration, max_batch_size, batch_table_name, gitlab_schema, queued_migration_version)
          # We keep track of the estimated number of tuples in 'total_tuple_count' to reason later
          # about the overall progress of a migration.
          safe_attributes_value = {
            max_batch_size: max_batch_size,
            total_tuple_count: Gitlab::Database::SharedModel.using_connection(connection) do
              Gitlab::Database::PgClass.for_table(batch_table_name)&.cardinality_estimate
            end,
            gitlab_schema: gitlab_schema,
            queued_migration_version: queued_migration_version
          }

          # rubocop:disable GitlabSecurity/PublicSend
          safe_attributes_value.each do |safe_attribute, value|
            migration.public_send("#{safe_attribute}=", value) if migration.respond_to?(safe_attribute)
          end
          # rubocop:enable GitlabSecurity/PublicSend
        end

        def prevent_early_finalization!(queued_migration_version, version)
          return if version.to_s <= ENFORCE_EARLY_FINALIZATION_FROM_VERSION || queued_migration_version.blank?

          queued_migration_milestone = Gitlab::Utils::BatchedBackgroundMigrationsDictionary
                                         .new(queued_migration_version)
                                         .milestone

          return unless queued_migration_milestone.present?

          queued_migration_milestone = Gitlab::VersionInfo.parse_from_milestone(queued_migration_milestone)
          last_required_stop = Gitlab::Database.upgrade_path.last_required_stop

          raise EARLY_FINALIZATION_ERROR unless queued_migration_milestone <= last_required_stop
        end
      end
    end
  end
end
