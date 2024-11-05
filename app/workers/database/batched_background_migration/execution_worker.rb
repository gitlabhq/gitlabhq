# frozen_string_literal: true

module Database
  module BatchedBackgroundMigration
    module ExecutionWorker
      extend ActiveSupport::Concern
      include ExclusiveLeaseGuard
      include Gitlab::Utils::StrongMemoize
      include ApplicationWorker
      include LimitedCapacity::Worker

      INTERVAL_VARIANCE = 5.seconds.freeze
      LEASE_TIMEOUT_MULTIPLIER = 3

      included do
        data_consistency :always
        feature_category :database
        prefer_calling_context_feature_category true
        queue_namespace :batched_background_migrations
      end

      class_methods do
        def max_running_jobs
          Gitlab::CurrentSettings.database_max_running_batched_background_migrations
        end

        # We have to override this one, as we want
        # arguments passed as is, and not duplicated
        def perform_with_capacity(args)
          worker = new
          worker.remove_failed_jobs

          bulk_perform_async(args)
        end
      end

      def remaining_work_count(*args)
        0 # the cron worker is the only source of new jobs
      end

      def max_running_jobs
        self.class.max_running_jobs
      end

      def perform_work(database_name, migration_id)
        self.database_name = database_name

        return unless enabled?
        return if shares_db_config?

        Gitlab::Database::SharedModel.using_connection(base_model.connection) do
          self.migration = find_migration(migration_id)

          break unless migration

          try_obtain_lease do
            run_migration_job if executable_migration?
          end
        end
      end

      private

      attr_accessor :database_name, :migration

      def enabled?
        return false if Feature.enabled?(:disallow_database_ddl_feature_flags, type: :ops)

        Feature.enabled?(:execute_batched_migrations_on_schedule, type: :ops)
      end

      def shares_db_config?
        Gitlab::Database.db_config_share_with(base_model.connection_db_config).present?
      end

      def base_model
        strong_memoize(:base_model) do
          Gitlab::Database.database_base_models[database_name]
        end
      end

      def find_migration(id)
        Gitlab::Database::BackgroundMigration::BatchedMigration.find_executable(id, connection: base_model.connection)
      end

      def lease_key
        @lease_key ||= [
          self.class.name.underscore,
          'database_name',
          database_name,
          'table_name',
          migration.table_name
        ].join(':')
      end

      def lease_timeout
        migration.interval * LEASE_TIMEOUT_MULTIPLIER
      end

      def executable_migration?
        migration.active? && migration.interval_elapsed?(variance: INTERVAL_VARIANCE)
      end

      def run_migration_job
        Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.new(connection: base_model.connection)
          .run_migration_job(migration)
      end
    end
  end
end
