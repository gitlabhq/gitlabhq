# frozen_string_literal: true

module Ci
  class DestroyPipelineService < BaseService
    def execute(pipeline)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_pipeline, pipeline)

      Ci::ExpirePipelineCacheService.new.execute(pipeline, delete: true)

      pipeline.cancel_running if pipeline.cancelable?

      # Ci::Pipeline#destroy triggers `use_fast_destroy :job_artifacts` and
      # ci_builds has ON DELETE CASCADE to ci_pipelines. The pipeline, the builds,
      # job and pipeline artifacts all get destroyed here.
      pipeline.reset.destroy!

      ServiceResponse.success(message: 'Pipeline not found')
    rescue ActiveRecord::RecordNotFound
      ServiceResponse.error(message: 'Pipeline not found')
    end
  end
end
