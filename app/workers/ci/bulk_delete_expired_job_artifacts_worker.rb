# frozen_string_literal: true

module Ci
  class BulkDeleteExpiredJobArtifactsWorker
    include ApplicationWorker
    include LimitedCapacity::Worker
    include ::Gitlab::LoopHelpers

    idempotent!
    # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- LP_DEAD doesn't exist on replicas
    # causing timeout for the queries. Switch back to :sticky once the worker is caught-up
    data_consistency :always
    # rubocop:enable SidekiqLoadBalancing/WorkerDataConsistency
    feature_category :job_artifacts

    BATCH_SIZE = 100
    LOOP_LIMIT = 500
    LOOP_TIMEOUT = 5.minutes

    def self.max_running_jobs_limit
      if Feature.enabled?(:bulk_delete_job_artifacts_high_concurrency, :instance)
        10
      else
        5
      end
    end

    def perform_work
      return unless Feature.enabled?(:bulk_delete_job_artifacts, :instance)

      @mod_bucket = Gitlab::Ci::Artifacts::BucketManager.claim_bucket
      log_extra_metadata_on_done(:mod_bucket, @mod_bucket)
      return unless @mod_bucket

      @bucket_claimed = true
      removed_artifacts_count = 0

      loop_until(timeout: LOOP_TIMEOUT, limit: LOOP_LIMIT) do
        artifacts = get_artifacts
        if artifacts.empty?
          log_extra_metadata_on_done(:artifacts_empty, true)
          break
        end

        service_response = destroy_batch(artifacts)
        removed_artifacts_count += service_response[:destroyed_artifacts_count]
      end

      log_extra_metadata_on_done(:destroyed_job_artifacts_count, removed_artifacts_count)

      Gitlab::Ci::Artifacts::BucketManager.release_bucket(@mod_bucket, max_buckets: max_running_jobs)
      log_extra_metadata_on_done(:mod_bucket_released, @mod_bucket)
    end

    def remaining_work_count
      # Don't re-enqueue if we couldn't claim a bucket - let the cron job handle it
      return 0 unless @bucket_claimed

      # rubocop:disable CodeReuse/ActiveRecord -- specific to cron worker
      if Ci::JobArtifact.expired_before(Time.current).non_trace.artifact_unlocked
          .where('MOD(project_id + job_id, ?) = ?', max_running_jobs, @mod_bucket).exists?
        999
      else
        0
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end

    def max_running_jobs
      self.class.max_running_jobs_limit
    end

    private

    def get_artifacts
      if @mod_bucket >= max_running_jobs
        log_extra_metadata_on_done(:terminated_early_due_to_scale_down, true)

        return []
      end

      Ci::JobArtifact
        .expired_before(Time.current)
        .non_trace
        .artifact_unlocked
        .where('MOD(project_id + job_id, ?) = ?', max_running_jobs, @mod_bucket) # rubocop:disable CodeReuse/ActiveRecord -- specific to cron worker
        .limit(BATCH_SIZE)
    end

    def destroy_batch(artifacts)
      Ci::JobArtifacts::DestroyBatchService.new(artifacts, skip_projects_on_refresh: true).execute
    end
  end
end
