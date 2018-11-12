# frozen_string_literal: true

module Ci
  class DestroyPipelineService < BaseService
    def execute(pipeline)
      return false unless can?(current_user, :destroy_pipeline, project)

      AuditEventService.new(current_user, pipeline).security_event

      pipeline.destroy
    end
  end
end
