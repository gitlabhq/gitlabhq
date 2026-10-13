# frozen_string_literal: true

module Integrations
  module SlackEvents
    class AgentDmService < AppMentionedService
      def execute
        return ServiceResponse.success if bot_message? || subtype_message? || mentions_bot?

        super
      end

      private

      def bot_message?
        slack_event[:bot_id].present?
      end

      def subtype_message?
        slack_event[:subtype].present?
      end

      # An @mention in a group DM also fires `app_mention`, which
      # AppMentionedService handles, so skip it here to avoid running the flow
      # twice. 1:1 DMs never fire `app_mention`, so they must be handled here.
      def mentions_bot?
        return false unless slack_event[:channel_type] == 'mpim'

        bot_user_id = slack_installation&.bot_user_id
        return false unless bot_user_id

        slack_event[:text].to_s.include?("<@#{bot_user_id}>")
      end
    end
  end
end
