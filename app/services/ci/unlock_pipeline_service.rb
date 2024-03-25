# frozen_string_literal: true

module Ci
  class UnlockPipelineService
    include BaseServiceUtility
    include ::Gitlab::ExclusiveLeaseHelpers

    ExecutionTimeoutError = Class.new(StandardError)

    BATCH_SIZE = 100
    MAX_EXEC_DURATION = 10.minutes.freeze
    LOCK_TIMEOUT = (MAX_EXEC_DURATION + 1.minute).freeze

    def initialize(pipeline)
      @pipeline = pipeline
      @already_leased = false
      @already_unlocked = false
      @exec_timeout = false
      @unlocked_job_artifacts_count = 0
      @unlocked_pipeline_artifacts_count = 0
    end

    def execute
      unlock_pipeline_exclusively

      success(
        skipped_already_leased: already_leased,
        skipped_already_unlocked: already_unlocked,
        exec_timeout: exec_timeout,
        unlocked_job_artifacts: unlocked_job_artifacts_count,
        unlocked_pipeline_artifacts: unlocked_pipeline_artifacts_count
      )
    end

    private

    attr_reader :pipeline, :already_leased, :already_unlocked, :exec_timeout,
      :unlocked_job_artifacts_count, :unlocked_pipeline_artifacts_count

    def unlock_pipeline_exclusively
      in_lock(lock_key, ttl: LOCK_TIMEOUT, retries: 0) do
        # Even though we enforce uniqueness when enqueueing pipelines, there is still a rare race condition chance that
        # a pipeline can be re-enqueued right after a worker pops off the same pipeline ID from the queue, and then just
        # after it completing the unlock process and releasing the lock, another worker picks up the re-enqueued
        # pipeline ID. So let's make sure to only unlock artifacts if the pipeline has not been unlocked.
        if pipeline.unlocked?
          @already_unlocked = true
          break
        end

        unlock_job_artifacts
        unlock_pipeline_artifacts

        # Marking the row in `ci_pipelines` to unlocked signifies that all artifacts have
        # already been unlocked. This must always happen last.
        unlock_pipeline
      end
    rescue ExecutionTimeoutError
      @exec_timeout = true
    rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
      @already_leased = true
    ensure
      if pipeline.unlocked?
        Ci::UnlockPipelineRequest.log_event(:completed, pipeline.id) unless already_unlocked
      else
        # This is to ensure to re-enqueue the pipeline in 2 occasions:
        # 1. When an unexpected error happens.
        # 2. When the execution timeout has been reached in the case of a pipeline having a lot of
        #    job artifacts. This allows us to continue unlocking the rest of the artifacts from
        #    where we left off. This is why we unlock the pipeline last.
        Ci::UnlockPipelineRequest.enqueue(pipeline.id)
        Ci::UnlockPipelineRequest.log_event(:re_enqueued, pipeline.id)
      end
    end

    def lock_key
      "ci:unlock_pipeline_service:lock:#{pipeline.id}"
    end

    def unlock_pipeline
      pipeline.update_column(:locked, Ci::Pipeline.lockeds[:unlocked])
    end

    def unlock_job_artifacts
      start = Time.current

      builds_relation.each_batch(of: BATCH_SIZE) do |builds|
        # rubocop: disable CodeReuse/ActiveRecord
        Ci::JobArtifact.where(job_id: builds.pluck(:id), partition_id: partition_id)
                       .each_batch(of: BATCH_SIZE) do |job_artifacts|
          unlocked_count = Ci::JobArtifact.where(
            id: job_artifacts.pluck(:id),
            partition_id: partition_id
          ).update_all(locked: :unlocked)

          @unlocked_job_artifacts_count ||= 0
          @unlocked_job_artifacts_count += unlocked_count

          raise ExecutionTimeoutError if (Time.current - start) > MAX_EXEC_DURATION
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end

    # Removes the partition_id filter from the query until we get more data in the
    # second partition.
    def builds_relation
      if Feature.enabled?(:disable_ci_partition_pruning, pipeline.project, type: :wip)
        Ci::Build.in_pipelines(pipeline)
      else
        pipeline.builds
      end
    end

    # All the partitionable entities connected to a pipeline
    # belong to the same partition where the pipeline is.
    def partition_id
      pipeline.partition_id
    end

    def unlock_pipeline_artifacts
      @unlocked_pipeline_artifacts_count = pipeline.pipeline_artifacts.update_all(locked: :unlocked)
    end
  end
end
