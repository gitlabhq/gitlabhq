# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module GitLabCliActivityUniqueCounter
      GITLAB_CLI_API_REQUEST_ACTION = 'i_code_review_user_gitlab_cli_api_request'

      # This regex will match to user agents ending with GitLab CLI or starting with glab/v"
      GITLAB_CLI_USER_AGENT_REGEX = %r{(GitLab\sCLI$|^glab/v)}

      class << self
        def track_api_request_when_trackable(user_agent:, user:)
          user_agent&.match?(GITLAB_CLI_USER_AGENT_REGEX) && track_unique_action_by_user(GITLAB_CLI_API_REQUEST_ACTION, user)
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
