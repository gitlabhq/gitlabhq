# frozen_string_literal: true

module Ci
  class PipelineSuccessUnlockArtifactsWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include PipelineBackgroundQueue

    idempotent!

    def perform(pipeline_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        break unless pipeline.has_archive_artifacts?

        ::Ci::UnlockArtifactsService
          .new(pipeline.project, pipeline.user)
          .execute(pipeline.ci_ref, pipeline)
      end
    end
  end
end
