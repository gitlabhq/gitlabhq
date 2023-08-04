# frozen_string_literal: true

module Ci
  class PipelineSuccessUnlockArtifactsWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    data_consistency :always

    sidekiq_options retry: 3

    idempotent!

    defer_on_database_health_signal :gitlab_ci, [:ci_job_artifacts]

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
