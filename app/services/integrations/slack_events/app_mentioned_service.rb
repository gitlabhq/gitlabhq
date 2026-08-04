# frozen_string_literal: true

module Integrations
  module SlackEvents
    class AppMentionedService
      include Gitlab::Utils::StrongMemoize

      DUO_SLACK_DOCS_URL = 'https://docs.gitlab.com/user/project/integrations/gitlab_slack_application/#gitlab-duo'
      PRIVACY_NOTICE_ACKNOWLEDGE_ACTION_ID = 'duo_privacy_notice_acknowledge'
      PRIVACY_NOTICE_DECLINE_ACTION_ID = 'duo_privacy_notice_decline'

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
          slack_api.add_reaction(channel: channel_id, name: 'lock', timestamp: message_ts)
          slack_api.post_ephemeral(
            channel: channel_id, user: slack_user_id,
            text: 'You do not have access to this feature yet. ' \
              "For more information, see #{DUO_SLACK_DOCS_URL}",
            thread_ts: ephemeral_thread_ts
          )
          return ServiceResponse.success
        end

        unless gitlab_user.allowed_to_use?(:duo_agent_platform)
          slack_api.add_reaction(channel: channel_id, name: 'lock', timestamp: message_ts)
          slack_api.post_ephemeral(
            channel: channel_id, user: slack_user_id,
            text: 'This feature requires GitLab Duo Agent Platform. ' \
              "For more information, see #{DUO_SLACK_DOCS_URL}",
            thread_ts: ephemeral_thread_ts
          )
          return ServiceResponse.success
        end

        if requires_privacy_notice?(gitlab_user)
          post_privacy_notice
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

      # Override in EE to return the namespace whose duo-workspace project
      # would record the session.
      def duo_workspace_namespace(_gitlab_user); end

      def requires_privacy_notice?(gitlab_user)
        return false if slack_gitlab_user_connection.duo_privacy_notice_acknowledged?
        return false unless duo_workspace_namespace(gitlab_user)

        non_public_channel?
      end

      # Fails closed: only conversations positively identified as public
      # channels skip the notice. Anything else (private channels, DMs,
      # group DMs, unknown future conversation types, or an undeterminable
      # channel type, for example an existing app installation without the
      # conversation read scopes) is treated as non-public.
      def non_public_channel?
        response = slack_api.conversation_info(channel: channel_id)
        return true unless response['ok']

        channel = response['channel']
        !(channel['is_channel'] && !channel['is_private'])
      end

      def post_privacy_notice
        slack_api.add_reaction(channel: channel_id, name: 'lock', timestamp: message_ts)
        options = {
          channel: channel_id,
          user: slack_user_id,
          text: privacy_notice_text,
          blocks: privacy_notice_blocks
        }
        options[:thread_ts] = thread_ts if slack_event[:thread_ts].present?

        slack_api.post_ephemeral(**options)
      end

      def privacy_notice_text
        s_("SlackIntegration|Heads up: your prompt and this thread's context are saved in a " \
          "GitLab Duo session. These are visible to anyone with access to the project it's saved in, " \
          'not just people in this conversation.')
      end

      def privacy_notice_blocks
        [
          {
            type: 'section',
            text: { type: 'mrkdwn', text: privacy_notice_text }
          },
          {
            type: 'actions',
            elements: [
              {
                type: 'button',
                style: 'primary',
                text: { type: 'plain_text', text: s_('SlackIntegration|Acknowledge and continue') },
                action_id: PRIVACY_NOTICE_ACKNOWLEDGE_ACTION_ID,
                value: privacy_notice_button_value
              },
              {
                type: 'button',
                text: { type: 'plain_text', text: s_('SlackIntegration|Cancel') },
                action_id: PRIVACY_NOTICE_DECLINE_ACTION_ID,
                value: privacy_notice_button_value
              }
            ]
          }
        ]
      end

      # `thread_ts` is only included when the mention was already inside a
      # thread, so the re-enqueued event preserves the original top-level vs
      # in-thread distinction.
      def privacy_notice_button_value
        Gitlab::Json.dump(
          channel: channel_id,
          ts: message_ts,
          thread_ts: slack_event[:thread_ts]
        )
      end

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
