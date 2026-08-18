# frozen_string_literal: true

module Integrations
  module SlackInteractions
    module SlackBlockActions
      class DuoPrivacyNoticeDeclineHandler < BaseHandler
        def execute
          swap_reaction
          replace_original_message(cancelled_text)
        end

        private

        def cancelled_text
          s_('SlackIntegration|Okay, GitLab Duo will not process this mention. ' \
            'Mention GitLab Duo again if you change your mind.')
        end

        def swap_reaction
          channel = button_value[:channel]
          message_ts = button_value[:ts]
          return unless channel.present? && message_ts.present?
          return unless slack_installation

          slack_api.remove_reaction(channel: channel, name: 'lock', timestamp: message_ts)
          slack_api.add_reaction(channel: channel, name: 'x', timestamp: message_ts)
        end
      end
    end
  end
end
