# frozen_string_literal: true

module Integrations
  module SlackEvents
    class AppMentionedService
      include Gitlab::Utils::StrongMemoize

      WIP_REPLY = "Thanks for the mention! I'm not ready to respond yet — stay tuned."

      def initialize(params)
        @params = params.with_indifferent_access
        @slack_event = (@params[:event] || {}).with_indifferent_access
        @slack_workspace_id = @params[:team_id]
        @slack_user_id = slack_event[:user]
        @channel_id = slack_event[:channel]
        @message_ts = slack_event[:ts]
        @thread_ts = slack_event[:thread_ts] || slack_event[:ts]
      end

      def execute
        return ServiceResponse.error(message: 'Missing Slack event data') unless valid_event?

        unless slack_installation
          Gitlab::IntegrationsLogger.info(
            slack_user_id: slack_user_id,
            slack_workspace_id: slack_workspace_id,
            message: 'SlackInstallation record has no bot token'
          )

          return ServiceResponse.success
        end

        gitlab_user = slack_gitlab_user_connection&.user

        # Handle case where Slack user is not linked to a GitLab account
        unless gitlab_user
          add_reaction('lock')
          ensure_user_linked
          return ServiceResponse.success
        end

        return ServiceResponse.success unless gitlab_user.can?(:use_slash_commands)

        unless Feature.enabled?(:slack_duo_agent, gitlab_user)
          add_reaction('lock')
          post_ephemeral('You do not have access to this feature yet.')
          return ServiceResponse.success
        end

        unless gitlab_user.allowed_to_use?(:duo_agent_platform)
          add_reaction('lock')
          post_ephemeral('This feature requires GitLab Duo Agent Platform.')
          return ServiceResponse.success
        end

        add_reaction('eyes')

        post_thread_reply(WIP_REPLY)

        remove_reaction('eyes')
        add_reaction('white_check_mark')

        ServiceResponse.success
      end

      private

      attr_reader :params, :slack_event, :slack_workspace_id, :slack_user_id, :channel_id, :message_ts, :thread_ts

      def valid_event?
        slack_workspace_id.present? && slack_user_id.present? && channel_id.present? && thread_ts.present?
      end

      def slack_installation
        SlackIntegration.with_bot.find_by_team_id(slack_workspace_id)
      end
      strong_memoize_attr :slack_installation

      def slack_api
        @slack_api ||= ::Slack::API.new(slack_installation)
      end

      def slack_gitlab_user_connection
        ChatNames::FindUserService.new(slack_workspace_id, slack_user_id).execute
      end
      strong_memoize_attr :slack_gitlab_user_connection

      def ensure_user_linked
        url = ChatNames::AuthorizeUserService.new(authorize_params).execute
        return unless url

        presenter = ::Gitlab::SlashCommands::Presenters::Access.new(url)
        text = presenter.authorize[:text]
        post_ephemeral(text)
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        Gitlab::ErrorTracking.track_exception(e, slack_workspace_id: slack_workspace_id)
      end

      def authorize_params
        {
          team_id: slack_workspace_id,
          team_domain: team_domain,
          user_id: slack_user_id,
          user_name: slack_event[:user]
        }
      end

      def team_domain
        return params[:team_domain] if params[:team_domain]

        slack_installation.team_name
      end

      def add_reaction(name)
        response = slack_api.post(
          'reactions.add',
          channel: channel_id,
          name: name,
          timestamp: message_ts
        )
        return response if response['ok']

        log_slack_error('Slack API error when adding reaction', response)
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        Gitlab::ErrorTracking.track_exception(e, slack_workspace_id: slack_workspace_id)
      end

      def remove_reaction(name)
        slack_api.post(
          'reactions.remove',
          channel: channel_id,
          name: name,
          timestamp: message_ts
        )
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        Gitlab::ErrorTracking.track_exception(e, slack_workspace_id: slack_workspace_id)
      end

      def post_thread_reply(text)
        response = slack_api.post(
          'chat.postMessage',
          channel: channel_id,
          thread_ts: thread_ts,
          text: text
        )
        return response if response['ok']

        log_slack_error('Slack API error when posting response', response)
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        Gitlab::ErrorTracking.track_exception(e, slack_workspace_id: slack_workspace_id)
      end

      def post_ephemeral(text)
        response = slack_api.post(
          'chat.postEphemeral',
          channel: channel_id,
          user: slack_user_id,
          text: text
        )
        return response if response['ok']

        log_slack_error('Slack API error when posting ephemeral message', response)
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        Gitlab::ErrorTracking.track_exception(e, slack_workspace_id: slack_workspace_id)
      end

      def log_slack_error(message, response)
        Gitlab::IntegrationsLogger.error(
          message: message,
          slack_workspace_id: slack_workspace_id,
          slack_user_id: slack_user_id,
          channel_id: channel_id,
          response: response.respond_to?(:to_h) ? response.to_h : response.to_s
        )
      end
    end
  end
end
