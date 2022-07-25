# frozen_string_literal: true

module Ci
  class DestroyPipelineService < BaseService
    def execute(pipeline)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_pipeline, pipeline)

      Ci::ExpirePipelineCacheService.new.execute(pipeline, delete: true)

      pipeline.cancel_running(cascade_to_children: true, execute_async: false) if pipeline.cancelable?

      # The pipeline, the builds, job and pipeline artifacts all get destroyed here.
      # Ci::Pipeline#destroy triggers fast destroy on job_artifacts and
      # build_trace_chunks to remove the records and data stored in object storage.
      # ci_builds records are deleted using ON DELETE CASCADE from ci_pipelines
      #
      pipeline.reset.destroy!

      ServiceResponse.success(message: 'Pipeline not found')
    rescue ActiveRecord::RecordNotFound
      ServiceResponse.error(message: 'Pipeline not found')
    end
  end
end
