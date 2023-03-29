# frozen_string_literal: true

module Ci
  # This worker is triggered when the pipeline state
  # changes into one of the stopped statuses
  # `Ci::Pipeline.stopped_statuses`.
  # It unlocks the previous pipelines on the same ref
  # as the pipeline that has just completed
  # using `Ci::UnlockArtifactsService`.
  class UnlockRefArtifactsOnPipelineStopWorker
    include ApplicationWorker

    data_consistency :always

    include PipelineBackgroundQueue

    idempotent!

    def perform(pipeline_id)
      pipeline = ::Ci::Pipeline.find_by_id(pipeline_id)

      return if pipeline.nil?
      return if pipeline.ci_ref.nil?

      results = ::Ci::UnlockArtifactsService
        .new(pipeline.project, pipeline.user)
        .execute(pipeline.ci_ref, pipeline)

      log_extra_metadata_on_done(:unlocked_pipelines, results[:unlocked_pipelines])
      log_extra_metadata_on_done(:unlocked_job_artifacts, results[:unlocked_job_artifacts])
    end
  end
end
