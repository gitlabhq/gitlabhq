# frozen_string_literal: true

module Ci
  class BulkDeleteExpiredJobArtifactsWorker
    include ApplicationWorker
    include LimitedCapacity::Worker

    idempotent!
    # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- LP_DEAD doesn't exist on replicas
    # causing timeout for the queries. Switch back to :sticky once the worker is caught-up
    data_consistency :always
    # rubocop:enable SidekiqLoadBalancing/WorkerDataConsistency
    feature_category :job_artifacts

    def self.max_running_jobs_limit
      5
    end

    def perform_work
      @mod_bucket = Gitlab::Ci::Artifacts::BucketManager.claim_bucket
      log_extra_metadata_on_done(:mod_bucket, @mod_bucket)
      return unless @mod_bucket

      @bucket_claimed = true

      if @mod_bucket >= max_running_jobs
        log_extra_metadata_on_done(:terminated_early_due_to_scale_down, true)
        release_bucket(destroyed: 0)
        return
      end

      result = Ci::JobArtifacts::DestroyAllExpiredService
        .new(mod_bucket: @mod_bucket, max_buckets: max_running_jobs)
        .execute

      @more_work_likely = result.more_work_likely
      log_extra_metadata_on_done(:drain_loops, result.drain_loops)
      log_extra_metadata_on_done(:partitions_exhausted, result.partitions_exhausted)
      log_extra_metadata_on_done(:exited_early, result.exited_early)
      release_bucket(destroyed: result.destroyed_count)
    end

    def remaining_work_count
      # Don't re-enqueue if we couldn't claim a bucket - let the cron job handle it
      return 0 unless @bucket_claimed

      @more_work_likely ? 999 : 0
    end

    def max_running_jobs
      self.class.max_running_jobs_limit
    end

    private

    def release_bucket(destroyed:)
      log_extra_metadata_on_done(:destroyed_job_artifacts_count, destroyed)
      Gitlab::Ci::Artifacts::BucketManager.release_bucket(@mod_bucket, max_buckets: max_running_jobs)
      log_extra_metadata_on_done(:mod_bucket_released, @mod_bucket)
    end
  end
end
