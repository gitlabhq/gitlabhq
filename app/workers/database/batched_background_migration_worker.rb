# frozen_string_literal: true

module Database
  class BatchedBackgroundMigrationWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :database
    idempotent!

    def perform
      return unless Feature.enabled?(:execute_batched_migrations_on_schedule, type: :ops) && active_migration

      with_exclusive_lease(active_migration.interval) do
        # Now that we have the exclusive lease, reload migration in case another process has changed it.
        # This is a temporary solution until we have better concurrency handling around job execution
        #
        # We also have to disable this cop, because ApplicationRecord aliases reset to reload, but our database
        # models don't inherit from ApplicationRecord
        active_migration.reload # rubocop:disable Cop/ActiveRecordAssociationReload

        run_active_migration if active_migration.active? && active_migration.interval_elapsed?
      end
    end

    private

    def active_migration
      @active_migration ||= Gitlab::Database::BackgroundMigration::BatchedMigration.active_migration
    end

    def run_active_migration
      Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.new.run_migration_job(active_migration)
    end

    def with_exclusive_lease(timeout)
      lease = Gitlab::ExclusiveLease.new(lease_key, timeout: timeout * 2)

      yield if lease.try_obtain
    ensure
      lease&.cancel
    end

    def lease_key
      self.class.name.demodulize.underscore
    end
  end
end
