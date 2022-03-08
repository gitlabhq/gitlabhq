# frozen_string_literal: true

module Database
  module BatchedBackgroundMigration
    module SingleDatabaseWorker
      extend ActiveSupport::Concern

      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

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

        Gitlab::Database::SharedModel.using_connection(base_model.connection) do
          break unless Feature.enabled?(:execute_batched_migrations_on_schedule, type: :ops, default_enabled: :yaml) && active_migration

          with_exclusive_lease(active_migration.interval) do
            # Now that we have the exclusive lease, reload migration in case another process has changed it.
            # This is a temporary solution until we have better concurrency handling around job execution
            #
            # We also have to disable this cop, because ApplicationRecord aliases reset to reload, but our database
            # models don't inherit from ApplicationRecord
            active_migration.reload # rubocop:disable Cop/ActiveRecordAssociationReload

            run_active_migration if active_migration.active? && active_migration.interval_elapsed?(variance: INTERVAL_VARIANCE)
          end
        end
      end

      private

      def active_migration
        @active_migration ||= Gitlab::Database::BackgroundMigration::BatchedMigration.active_migration
      end

      def run_active_migration
        Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.new(connection: base_model.connection).run_migration_job(active_migration)
      end

      def base_model
        @base_model ||= Gitlab::Database.database_base_models[self.class.tracking_database]
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
