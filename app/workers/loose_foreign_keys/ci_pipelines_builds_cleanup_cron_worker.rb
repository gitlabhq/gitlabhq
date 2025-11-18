# frozen_string_literal: true

module LooseForeignKeys # rubocop: disable Gitlab/BoundedContexts -- This module is used for database cleanup workers
  class CiPipelinesBuildsCleanupCronWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext -- this is a cronjob.

    sidekiq_options retry: false
    feature_category :database
    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- this is a cronjob.
    idempotent!

    def perform
      modification_tracker, turbo_mode = initialize_modification_tracker

      # Add small buffer on MAX_RUNTIME to account for single long-running
      # query or extra worker time after the cleanup.
      lock_ttl = modification_tracker.max_runtime + 10.seconds

      in_lock(self.class.name.underscore, ttl: lock_ttl, retries: 0) do
        stats = ProcessDeletedRecordsService.new(
          connection: Ci::ApplicationRecord.connection,
          modification_tracker: modification_tracker,
          logger: Sidekiq.logger,
          worker_class: self.class
        ).execute
        stats[:turbo_mode] = turbo_mode

        log_extra_metadata_on_done(:stats, stats)
      end
    end

    private

    def initialize_modification_tracker
      turbo_mode = Feature.enabled?(:loose_foreign_keys_turbo_mode_ci, :instance, type: :ops)
      modification_tracker = turbo_mode ? TurboModificationTracker.new : ModificationTracker.new
      [modification_tracker, turbo_mode]
    end
  end
end
