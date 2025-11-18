# frozen_string_literal: true

module LooseForeignKeys # rubocop: disable Gitlab/BoundedContexts -- This module is used for database cleanup workers
  class MergeRequestDiffCommitCleanupWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext -- this is a cronjob.

    sidekiq_options retry: false
    feature_category :code_review_workflow
    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- this is a cronjob.
    idempotent!

    def perform
      if vacuum_running_on_merge_request_diff_commits?
        log_extra_metadata_on_done(:vacuum_running, true)
        return
      end

      modification_tracker = ModificationTracker.new

      lock_ttl = modification_tracker.max_runtime + 10.seconds

      in_lock(self.class.name.underscore, ttl: lock_ttl, retries: 0) do
        stats = ProcessDeletedRecordsService.new(
          connection: ApplicationRecord.connection,
          modification_tracker: modification_tracker,
          logger: Sidekiq.logger,
          worker_class: self.class
        ).execute

        log_extra_metadata_on_done(:stats, stats)
      end
    end

    private

    def vacuum_running_on_merge_request_diff_commits?
      Gitlab::Database::PostgresAutovacuumActivity.for_tables(['merge_request_diff_commits']).present?
    end
  end
end
