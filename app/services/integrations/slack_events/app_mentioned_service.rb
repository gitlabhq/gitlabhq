# frozen_string_literal: true

module Integrations
  module SlackEvents
    class AppMentionedService
      include Gitlab::Utils::StrongMemoize

      DUO_SLACK_DOCS_URL = 'https://docs.gitlab.com/user/project/integrations/gitlab_slack_application/#gitlab-duo'

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

        unless gitlab_user
          ensure_user_linked
          slack_api.add_reaction(channel: channel_id, name: 'lock', timestamp: message_ts)
          return ServiceResponse.success
        end

        return ServiceResponse.success unless gitlab_user.can?(:use_slash_commands)

        unless Feature.enabled?(:slack_duo_agent, gitlab_user)
          post_no_access_message(
            'You do not have access to this feature yet. ' \
              "For more information, see #{DUO_SLACK_DOCS_URL}"
          )
          return ServiceResponse.success
        end

        unless experiment_features_available?(gitlab_user)
          post_no_access_message(
            'This feature requires experiment and beta GitLab Duo features to be turned on. ' \
              "For more information, see #{DUO_SLACK_DOCS_URL}"
          )
          return ServiceResponse.success
        end

        unless gitlab_user.allowed_to_use?(:duo_agent_platform)
          post_no_access_message(
            'This feature requires GitLab Duo Agent Platform. ' \
              "For more information, see #{DUO_SLACK_DOCS_URL}"
          )
          return ServiceResponse.success
        end

        trigger_duo_flow(gitlab_user)

        ServiceResponse.success
      end

      private

      attr_reader :params, :slack_event, :slack_workspace_id, :slack_user_id, :channel_id, :message_ts, :thread_ts

      def valid_event?
        slack_workspace_id.present? && slack_user_id.present? && channel_id.present? && thread_ts.present?
      end

      # Returns the thread_ts to use for ephemeral messages, so they appear
      # inside the thread when the bot was mentioned within one. When the
      # mention is at the channel root (thread_ts == message_ts), returns nil
      # so the ephemeral is posted at the channel root (existing behaviour).
      def ephemeral_thread_ts
        thread_ts != message_ts ? thread_ts : nil
      end

      # Overridden in EE. GitLab Duo in Slack is an EE-only feature.
      def experiment_features_available?(_gitlab_user)
        false
      end

      def post_no_access_message(text)
        slack_api.add_reaction(channel: channel_id, name: 'lock', timestamp: message_ts)
        slack_api.post_ephemeral(
          channel: channel_id, user: slack_user_id, text: text, thread_ts: ephemeral_thread_ts
        )
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

      # Override in EE to trigger a Duo flow.
      def trigger_duo_flow(_gitlab_user); end

      def ensure_user_linked
        url = ChatNames::AuthorizeUserService.new(authorize_params).execute
        return unless url

        presenter = ::Gitlab::SlashCommands::Presenters::Access.new(url)
        slack_api.post_ephemeral(
          channel: channel_id,
          user: slack_user_id,
          text: presenter.authorize_for_mention[:text],
          thread_ts: ephemeral_thread_ts
        )
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
    end
  end
end

Integrations::SlackEvents::AppMentionedService.prepend_mod
