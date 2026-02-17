# frozen_string_literal: true

module Ci
  class ScheduleBulkDeleteJobArtifactCronWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- does not perform work scoped to a context

    idempotent!
    feature_category :job_artifacts
    data_consistency :sticky

    def perform
      return unless Feature.enabled?(:bulk_delete_job_artifacts, :instance)

      max_buckets = Ci::BulkDeleteExpiredJobArtifactsWorker.max_running_jobs_limit
      stale_buckets = Gitlab::Ci::Artifacts::BucketManager.recover_stale_buckets

      active_buckets = Gitlab::Ci::Artifacts::BucketManager.enqueue_missing_buckets(
        max_buckets: max_buckets
      )

      Ci::BulkDeleteExpiredJobArtifactsWorker.perform_with_capacity

      log_hash_metadata_on_done(
        max_buckets: max_buckets,
        available_count: active_buckets[:available].count,
        occupied_count: active_buckets[:occupied].count,
        stale_count: stale_buckets.count,
        missing_count: active_buckets[:missing].count
      )
    end
  end
end
