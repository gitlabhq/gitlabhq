# frozen_string_literal: true

module Ci
  # TODO: Clean up this worker in a subsequent release.
  # The process to unlock job artifacts have been moved to
  # be triggered by the pipeline state transitions and
  # to use UnlockRefArtifactsOnPipelineStopWorker.
  # https://gitlab.com/gitlab-org/gitlab/-/issues/397491
  class PipelineSuccessUnlockArtifactsWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include PipelineBackgroundQueue

    idempotent!

    def perform(pipeline_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        # TODO: Move this check inside the Ci::UnlockArtifactsService
        # once the feature flags in it have been removed.
        break unless pipeline.has_erasable_artifacts?

        results = ::Ci::UnlockArtifactsService
          .new(pipeline.project, pipeline.user)
          .execute(pipeline.ci_ref, pipeline)

        log_extra_metadata_on_done(:unlocked_pipelines, results[:unlocked_pipelines])
        log_extra_metadata_on_done(:unlocked_job_artifacts, results[:unlocked_job_artifacts])
      end
    end
  end
end
