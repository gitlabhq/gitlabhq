# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module JetBrainsBundledPluginActivityUniqueCounter
      JETBRAINS_BUNDLED_API_REQUEST_ACTION = 'i_editor_extensions_user_jetbrains_bundled_api_request'
      JETBRAINS_BUNDLED_USER_AGENT_REGEX = /\AIntelliJ-GitLab-Plugin/

      class << self
        def track_api_request_when_trackable(user_agent:, user:)
          user_agent&.match?(JETBRAINS_BUNDLED_USER_AGENT_REGEX) &&
            track_unique_action_by_user(JETBRAINS_BUNDLED_API_REQUEST_ACTION, user)
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
