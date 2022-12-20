# frozen_string_literal: true

module Ci
  class PlayBridgeService < ::BaseService
    def execute(bridge)
      check_access!(bridge)

      Ci::EnqueueJobService.new(bridge, current_user: current_user).execute
    end

    private

    def check_access!(bridge)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :play_job, bridge)
    end
  end
end

Ci::PlayBridgeService.prepend_mod_with('Ci::PlayBridgeService')
