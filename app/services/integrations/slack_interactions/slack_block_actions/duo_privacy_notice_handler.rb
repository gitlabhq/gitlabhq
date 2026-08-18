# frozen_string_literal: true

module Integrations
  module SlackInteractions
    module SlackBlockActions
      class DuoPrivacyNoticeHandler < BaseHandler
        def execute
          return unless team_id.present? && user_id.present?
          return unless chat_name

          chat_name.acknowledge_duo_privacy_notice!

          remove_lock_reaction
          resume_mention
          replace_original_message(confirmation_text)
        end

        private

        def confirmation_text
          s_('SlackIntegration|Thanks! Your acknowledgement was saved and GitLab Duo is processing ' \
            'your request. You will not be asked again in this workspace.')
        end

        def chat_name
          ChatNames::FindUserService.new(team_id, user_id).execute
        end
        strong_memoize_attr :chat_name

        def remove_lock_reaction
          channel = button_value[:channel]
          message_ts = button_value[:ts]
          return unless channel.present? && message_ts.present?
          return unless slack_installation

          slack_api.remove_reaction(channel: channel, name: 'lock', timestamp: message_ts)
        end

        # The re-enqueued event carries no `text` because Slack limits button
        # values to 2000 characters. The EE service recovers the message text
        # from the thread via the Slack conversations.replies API instead.
        def resume_mention
          channel = button_value[:channel]
          message_ts = button_value[:ts]
          return unless channel.present? && message_ts.present?

          Integrations::SlackEventWorker.perform_async(
            slack_event: 'app_mention',
            params: {
              team_id: team_id,
              event_id: "duo-privacy-ack-#{team_id}-#{channel}-#{message_ts}",
              event: {
                type: 'app_mention',
                user: user_id,
                channel: channel,
                ts: message_ts,
                thread_ts: button_value[:thread_ts]
              }
            }
          )
        end
      end
    end
  end
end
