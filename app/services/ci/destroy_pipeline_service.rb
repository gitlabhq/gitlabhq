# frozen_string_literal: true

module Ci
  class DestroyPipelineService < BaseService
    def execute(pipeline)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_pipeline, pipeline)

      AuditEventService.new(current_user, pipeline).security_event

      pipeline.destroy!
    end
  end
end
