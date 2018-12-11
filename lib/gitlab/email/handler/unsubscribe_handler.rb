# frozen_string_literal: true

require 'gitlab/email/handler/base_handler'

module Gitlab
  module Email
    module Handler
      class UnsubscribeHandler < BaseHandler
        delegate :project, to: :sent_notification, allow_nil: true

        def can_handle?
          mail_key =~ /\A\w+#{Regexp.escape(suffix)}\z/
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
          @sent_notification ||= SentNotification.for(reply_key)
        end

        def suffix
          @suffix ||= if mail_key&.end_with?(Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX)
                        Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX
                      else
                        Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX_OLD
                      end
        end

        def reply_key
          mail_key.sub(suffix, '')
        end
      end
    end
  end
end
