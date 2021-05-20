# frozen_string_literal: true

module Ci
  class PlayBridgeService < ::BaseService
    def execute(bridge)
      check_access!(bridge)

      bridge.tap do |bridge|
        bridge.user = current_user
        bridge.enqueue!

        next unless ::Feature.enabled?(:ci_fix_pipeline_status_for_dag_needs_manual, project, default_enabled: :yaml)

        AfterRequeueJobService.new(project, current_user).execute(bridge)
      end
    end

    private

    def check_access!(bridge)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :play_job, bridge)
    end
  end
end

Ci::PlayBridgeService.prepend_mod_with('Ci::PlayBridgeService')
