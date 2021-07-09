# frozen_string_literal: true

module Ci
  class DestroyPipelineService < BaseService
    def execute(pipeline)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_pipeline, pipeline)

      Ci::ExpirePipelineCacheService.new.execute(pipeline, delete: true)

      pipeline.cancel_running if pipeline.cancelable? && ::Feature.enabled?(:cancel_pipelines_prior_to_destroy, default_enabled: :yaml)

      pipeline.reset.destroy!

      ServiceResponse.success(message: 'Pipeline not found')
    rescue ActiveRecord::RecordNotFound
      ServiceResponse.error(message: 'Pipeline not found')
    end
  end
end
