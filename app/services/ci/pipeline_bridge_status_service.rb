# frozen_string_literal: true

module Ci
  class PipelineBridgeStatusService < ::BaseService
    def execute(pipeline)
      return unless pipeline.bridge_triggered?

      begin
        pipeline.source_bridge.inherit_status_from_downstream!(pipeline)
      rescue StateMachines::InvalidTransition => e
        error = Ci::Bridge::InvalidTransitionError.new(e.message)
        error.set_backtrace(caller)
        Gitlab::ErrorTracking.track_exception(
          error,
          bridge_id: pipeline.source_bridge.id,
          downstream_pipeline_id: pipeline.id)
      end
    end
  end
end

Ci::PipelineBridgeStatusService.prepend_mod_with('Ci::PipelineBridgeStatusService')
