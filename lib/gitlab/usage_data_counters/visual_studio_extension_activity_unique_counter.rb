# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module VisualStudioExtensionActivityUniqueCounter
      VISUAL_STUDIO_EXTENSION_API_REQUEST_ACTION = 'i_editor_extensions_user_visual_studio_api_request'
      VISUAL_STUDIO_EXTENSION_USER_AGENT_REGEX = /gl-visual-studio-extension/

      class << self
        def track_api_request_when_trackable(user_agent:, user:)
          user_agent&.match?(VISUAL_STUDIO_EXTENSION_USER_AGENT_REGEX) &&
            track_unique_action_by_user(VISUAL_STUDIO_EXTENSION_API_REQUEST_ACTION, user)
        end

        private

        def track_unique_action_by_user(action, user)
          return unless user

          track_unique_action(action, user.id)
        end

        def track_unique_action(action, value)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_usage_event(action, value)
        end
      end
    end
  end
end
