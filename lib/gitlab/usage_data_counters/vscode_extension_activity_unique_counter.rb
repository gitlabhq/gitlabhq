# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module VSCodeExtensionActivityUniqueCounter
      VS_CODE_API_REQUEST_ACTION = 'i_code_review_user_vs_code_api_request'

      class << self
        def track_api_request_when_trackable(user_agent:, user:)
          user_agent&.match?(Gitlab::Regex.vs_code_user_agent_regex) && track_unique_action_by_user(
            VS_CODE_API_REQUEST_ACTION, user)
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
