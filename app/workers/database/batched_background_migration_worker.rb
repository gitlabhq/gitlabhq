# frozen_string_literal: true

module Database
  class BatchedBackgroundMigrationWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :database
    tags :exclude_from_kubernetes
    idempotent!

    LEASE_TIMEOUT_MULTIPLIER = 3
    MINIMUM_LEASE_TIMEOUT = 10.minutes.freeze
    INTERVAL_VARIANCE = 5.seconds.freeze

    def perform
      return unless Feature.enabled?(:execute_batched_migrations_on_schedule, type: :ops, default_enabled: :yaml) && active_migration

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

    private

    def active_migration
      @active_migration ||= Gitlab::Database::BackgroundMigration::BatchedMigration.active_migration
    end

    def run_active_migration
      Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.new.run_migration_job(active_migration)
    end

    def with_exclusive_lease(interval)
      timeout = [interval * LEASE_TIMEOUT_MULTIPLIER, MINIMUM_LEASE_TIMEOUT].max
      lease = Gitlab::ExclusiveLease.new(lease_key, timeout: timeout)

      yield if lease.try_obtain
    ensure
      lease&.cancel
    end

    def lease_key
      self.class.name.demodulize.underscore
    end
  end
end
