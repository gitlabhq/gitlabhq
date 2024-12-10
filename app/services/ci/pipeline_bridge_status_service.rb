# frozen_string_literal: true

module Ci
  class PipelineBridgeStatusService < ::BaseService
    def execute(pipeline)
      return unless pipeline.bridge_triggered?

      pipeline.source_bridge.inherit_status_from_downstream!(pipeline)
    end
  end
end

Ci::PipelineBridgeStatusService.prepend_mod_with('Ci::PipelineBridgeStatusService')
