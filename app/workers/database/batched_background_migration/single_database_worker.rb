# frozen_string_literal: true

module Database
  module BatchedBackgroundMigration
    module SingleDatabaseWorker
      extend ActiveSupport::Concern

      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
      include Gitlab::Utils::StrongMemoize

      LEASE_TIMEOUT_MULTIPLIER = 3
      MINIMUM_LEASE_TIMEOUT = 10.minutes.freeze
      INTERVAL_VARIANCE = 5.seconds.freeze

      included do
        data_consistency :always
        feature_category :database
        idempotent!
      end

      class_methods do
        # :nocov:
        def tracking_database
          raise NotImplementedError, "#{self.name} does not implement #{__method__}"
        end
        # :nocov:

        def enabled?
          Feature.enabled?(:execute_batched_migrations_on_schedule, type: :ops)
        end

        def lease_key
          name.demodulize.underscore
        end
      end

      def perform
        unless base_model
          Sidekiq.logger.info(
            class: self.class.name,
            database: self.class.tracking_database,
            message: 'skipping migration execution for unconfigured database')

          return
        end

        if shares_db_config?
          Sidekiq.logger.info(
            class: self.class.name,
            database: self.class.tracking_database,
            message: 'skipping migration execution for database that shares database configuration with another database')

          return
        end

        Gitlab::Database::SharedModel.using_connection(base_model.connection) do
          break unless self.class.enabled? && active_migration

          with_exclusive_lease(active_migration.interval) do
            run_active_migration
          end
        end
      end

      private

      def active_migration
        @active_migration ||= Gitlab::Database::BackgroundMigration::BatchedMigration.active_migration(connection: base_model.connection)
      end

      def run_active_migration
        Database::BatchedBackgroundMigration::ExecutionWorker.new.perform(self.class.tracking_database, active_migration.id)
      end

      def base_model
        strong_memoize(:base_model) do
          Gitlab::Database.database_base_models[self.class.tracking_database]
        end
      end

      def shares_db_config?
        base_model && Gitlab::Database.db_config_share_with(base_model.connection_db_config).present?
      end

      def with_exclusive_lease(interval)
        timeout = [interval * LEASE_TIMEOUT_MULTIPLIER, MINIMUM_LEASE_TIMEOUT].max
        lease = Gitlab::ExclusiveLease.new(self.class.lease_key, timeout: timeout)

        yield if lease.try_obtain
      ensure
        lease&.cancel
      end
    end
  end
end
