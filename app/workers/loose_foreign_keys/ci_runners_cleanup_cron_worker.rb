# frozen_string_literal: true

module LooseForeignKeys # rubocop: disable Gitlab/BoundedContexts -- This module is used for database cleanup workers
  class CiRunnersCleanupCronWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext -- this is a cronjob.

    sidekiq_options retry: false
    feature_category :database
    data_consistency :sticky
    idempotent!

    def perform
      modification_tracker = ModificationTracker.new
      lock_ttl = modification_tracker.max_runtime + 10.seconds

      in_lock(self.class.name.underscore, ttl: lock_ttl, retries: 0) do
        stats = ProcessDeletedRecordsService.new(
          connection: Ci::ApplicationRecord.connection,
          modification_tracker: modification_tracker,
          logger: Sidekiq.logger,
          worker_class: self.class,
          record_store: ::Gitlab::LooseForeignKeys::DeletedRecordStore
        ).execute

        log_extra_metadata_on_done(:stats, stats)
      end
    end
  end
end
