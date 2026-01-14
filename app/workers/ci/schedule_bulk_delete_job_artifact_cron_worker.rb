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

      Gitlab::Ci::Artifacts::BucketManager.recover_stale_buckets

      Gitlab::Ci::Artifacts::BucketManager.enqueue_missing_buckets(
        max_buckets: Ci::BulkDeleteExpiredJobArtifactsWorker.max_running_jobs_limit
      )

      Ci::BulkDeleteExpiredJobArtifactsWorker.perform_with_capacity
    end
  end
end
