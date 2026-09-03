# frozen_string_literal: true

module Integrations
  module SlackInteractions
    module SlackBlockActions
      # Base class for Slack block action handlers that respond to button
      # clicks on messages posted by the GitLab for Slack app. Provides shared
      # helpers for looking up the Slack installation and calling the Slack API.
      class BaseHandler
        include Gitlab::Utils::StrongMemoize

        def initialize(params, action)
          @params = params
          @action = action
          @team_id = params.dig(:team, :id)
          @user_id = params.dig(:user, :id)
        end

        def execute
          raise NotImplementedError
        end

        private

        attr_reader :params, :action, :team_id, :user_id

        def slack_installation
          SlackIntegration.with_bot.find_by_team_id(team_id)
        end
        strong_memoize_attr :slack_installation

        def slack_api
          ::Slack::API.new(slack_installation)
        end
        strong_memoize_attr :slack_api
      end
    end
  end
end
