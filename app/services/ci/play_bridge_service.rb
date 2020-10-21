# frozen_string_literal: true

module Ci
  class PlayBridgeService < ::BaseService
    def execute(bridge)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :play_job, bridge)

      bridge.tap do |bridge|
        bridge.user = current_user
        bridge.enqueue!
      end
    end
  end
end
