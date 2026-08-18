# frozen_string_literal: true

module Integrations
  module SlackInteractions
    module SlackBlockActions
      # Base class for Slack block action handlers that respond to button
      # clicks on messages posted by the GitLab for Slack app. Provides shared
      # helpers for parsing the button value payload, looking up the Slack
      # installation, and replacing the original message via the interaction
      # `response_url`.
      class BaseHandler
        include Gitlab::Utils::StrongMemoize

        def initialize(params, action)
          @params = params
          @action = action
          @team_id = params.dig(:team, :id)
          @user_id = params.dig(:user, :id)
          @response_url = params[:response_url]
        end

        def execute
          raise NotImplementedError
        end

        private

        attr_reader :params, :action, :team_id, :user_id, :response_url

        # Buttons carry a JSON-encoded value (max 2000 characters, enforced by
        # Slack). Returns an empty hash when the value is missing or invalid.
        def button_value
          parsed = Gitlab::Json::SafeParser.parse(action[:value].to_s)
          parsed.is_a?(Hash) ? parsed.with_indifferent_access : {}
        rescue JSON::ParserError
          {}
        end
        strong_memoize_attr :button_value

        def slack_installation
          SlackIntegration.with_bot.find_by_team_id(team_id)
        end
        strong_memoize_attr :slack_installation

        def slack_api
          ::Slack::API.new(slack_installation)
        end
        strong_memoize_attr :slack_api

        # Replaces the original interactive message (for example, an ephemeral
        # notice with buttons) with plain text via the `response_url` Slack
        # provides for the interaction.
        def replace_original_message(text)
          return unless response_url.present?

          Integrations::Clients::HTTP.post(
            response_url,
            body: Gitlab::Json.dump(replace_original: true, text: text),
            headers: { 'Content-Type' => 'application/json' }
          )
        rescue *Gitlab::HTTP::HTTP_ERRORS => e
          Gitlab::ErrorTracking.track_exception(e, slack_workspace_id: team_id)
        end
      end
    end
  end
end
