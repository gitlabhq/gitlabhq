# frozen_string_literal: true

module Ci
  class UnlockPipelinesInQueueWorker
    include ApplicationWorker

    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency

    include LimitedCapacity::Worker

    feature_category :build_artifacts
    idempotent!

    MAX_RUNNING_LOW = 5
    MAX_RUNNING_MEDIUM = 10
    MAX_RUNNING_HIGH = 20

    def perform_work(*_)
      pipeline_id = Ci::UnlockPipelineRequest.next!
      return log_extra_metadata_on_done(:remaining_pending, 0) unless pipeline_id

      Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        result = Ci::UnlockPipelineService.new(pipeline).execute

        log_extra_metadata_on_done(:remaining_pending, Ci::UnlockPipelineRequest.total_pending)
        log_extra_metadata_on_done(:pipeline_id, pipeline_id)
        log_extra_metadata_on_done(:skipped_already_leased, result[:skipped_already_leased])
        log_extra_metadata_on_done(:skipped_already_unlocked, result[:skipped_already_unlocked])
        log_extra_metadata_on_done(:exec_timeout, result[:exec_timeout])
        log_extra_metadata_on_done(:unlocked_job_artifacts, result[:unlocked_job_artifacts])
        log_extra_metadata_on_done(:unlocked_pipeline_artifacts, result[:unlocked_pipeline_artifacts])
      end
    end

    def remaining_work_count(*_)
      Ci::UnlockPipelineRequest.total_pending
    end

    def max_running_jobs
      if ::Feature.enabled?(:ci_unlock_pipelines_high, type: :ops)
        MAX_RUNNING_HIGH
      elsif ::Feature.enabled?(:ci_unlock_pipelines_medium, type: :ops)
        MAX_RUNNING_MEDIUM
      elsif ::Feature.enabled?(:ci_unlock_pipelines, type: :ops)
        MAX_RUNNING_LOW
      else
        0
      end
    end
  end
end
