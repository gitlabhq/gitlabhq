# frozen_string_literal: true

# Handles the Slack `app_home_opened` event sent from Slack to GitLab.
# Responds with a POST to the Slack API 'views.publish' method.
#
# See:
# - https://api.slack.com/methods/views.publish
# - https://api.slack.com/events/app_home_opened
module Integrations
  module SlackEvents
    class AppHomeOpenedService
      include Gitlab::Utils::StrongMemoize

      def initialize(params)
        @slack_user_id = params.dig(:event, :user)
        @slack_workspace_id = params[:team_id]
      end

      def execute
        # Legacy Slack App integrations will not yet have a token we can use
        # to call the Slack API. Do nothing, and consider the service successful.
        unless slack_installation
          logger.info(
            slack_user_id: slack_user_id,
            slack_workspace_id: slack_workspace_id,
            message: 'SlackInstallation record has no bot token'
          )

          return ServiceResponse.success
        end

        begin
          response = ::Slack::API.new(slack_installation).post(
            'views.publish',
            payload
          )
        rescue *Gitlab::HTTP::HTTP_ERRORS => e
          return ServiceResponse
            .error(message: 'HTTP exception when calling Slack API')
            .track_exception(
              as: e.class,
              slack_user_id: slack_user_id,
              slack_workspace_id: slack_workspace_id
            )
        end

        return ServiceResponse.success if response['ok']

        # For a list of errors, see:
        # https://api.slack.com/methods/views.publish#errors
        ServiceResponse.error(
          message: 'Slack API returned an error',
          payload: response
        ).track_exception(
          slack_user_id: slack_user_id,
          slack_workspace_id: slack_workspace_id,
          response: response.to_h
        )
      end

      private

      def slack_installation
        SlackIntegration.with_bot.find_by_team_id(slack_workspace_id)
      end
      strong_memoize_attr :slack_installation

      def slack_gitlab_user_connection
        ChatNames::FindUserService.new(slack_workspace_id, slack_user_id).execute
      end
      strong_memoize_attr :slack_gitlab_user_connection

      def payload
        {
          user_id: slack_user_id,
          view: ::Slack::BlockKit::AppHomeOpened.new(
            slack_user_id,
            slack_workspace_id,
            slack_gitlab_user_connection,
            slack_installation
          ).build
        }
      end

      def logger
        Gitlab::IntegrationsLogger
      end

      attr_reader :slack_user_id, :slack_workspace_id
    end
  end
end
