# frozen_string_literal: true

module Ci
  class DestroyPipelineService < BaseService
    def execute(pipeline)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_pipeline, pipeline)

      pipeline.destroy!

      Gitlab::Cache::Ci::ProjectPipelineStatus.new(pipeline.project).delete_from_cache
    end
  end
end
