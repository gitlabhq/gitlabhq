# frozen_string_literal: true

require 'gitlab/email/handler/base_handler'

# handles unsubscribe emails with these forms:
#   incoming+1234567890abcdef1234567890abcdef-unsubscribe@incoming.gitlab.com
#   incoming+1234567890abcdef1234567890abcdef+unsubscribe@incoming.gitlab.com (legacy)
module Gitlab
  module Email
    module Handler
      class UnsubscribeHandler < BaseHandler
        delegate :project, to: :sent_notification, allow_nil: true

        HANDLER_REGEX        = /\A(?<replytoken>\w+)#{Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX}\z/.freeze
        HANDLER_REGEX_LEGACY = /\A(?<replytoken>\w+)#{Regexp.escape(Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX_OLD)}\z/.freeze

        def initialize(mail, mail_key)
          super(mail, mail_key)

          matched = HANDLER_REGEX.match(mail_key.to_s) || HANDLER_REGEX_LEGACY.match(mail_key.to_s)
          @reply_token = matched[:replytoken] if matched
        end

        def can_handle?
          @reply_token.present?
        end

        def execute
          raise SentNotificationNotFoundError unless sent_notification
          return unless sent_notification.unsubscribable?

          noteable = sent_notification.noteable
          raise NoteableNotFoundError unless noteable

          noteable.unsubscribe(sent_notification.recipient)
        end

        private

        def sent_notification
          @sent_notification ||= SentNotification.for(@reply_token)
        end
      end
    end
  end
end
