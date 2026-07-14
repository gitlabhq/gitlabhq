# frozen_string_literal: true

require 'gitlab/email/handler/base_handler'

# handles unsubscribe emails with these formats:
#   incoming+1234567890abcdef1234567890abcdef-unsubscribe@incoming.gitlab.com
#   incoming+1234567890abcdef1234567890abcdef+unsubscribe@incoming.gitlab.com (legacy)
module Gitlab
  module Email
    module Handler
      class UnsubscribeHandler < BaseHandler
        extend ::Gitlab::Utils::Override

        delegate :project, to: :sent_notification, allow_nil: true

        def self.gem_handler
          :unsubscribe
        end

        override :can_handle?
        def can_handle?
          reply_token.present?
        end

        def execute
          raise SentNotificationNotFoundError unless sent_notification

          log_email_handler
          return unless sent_notification.unsubscribable?

          noteable = sent_notification.noteable
          raise NoteableNotFoundError unless noteable

          noteable.unsubscribe(sent_notification.recipient, sent_notification.project)
        end

        def metrics_event
          :receive_email_unsubscribe
        end

        private

        def reply_token
          return unless identification

          identification[:reply_token]
        end

        def parent_namespace
          sent_notification.namespace
        end

        def additional_log_data
          { Labkit::Fields::GL_SENT_NOTIFICATION_ID => sent_notification.id }
        end

        def sent_notification
          @sent_notification ||= SentNotification.for(reply_token)
        end
      end
    end
  end
end
