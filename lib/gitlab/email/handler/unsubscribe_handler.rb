require 'gitlab/email/handler/base_handler'

module Gitlab
  module Email
    module Handler
      class UnsubscribeHandler < BaseHandler
        delegate :project, to: :sent_notification, allow_nil: true

        def can_handle?
          mail_key =~ /\A\w+#{Regexp.escape(Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX)}\z/
        end

        def execute
          raise SentNotificationNotFoundError unless sent_notification
          return unless sent_notification.unsubscribable?

          noteable = sent_notification.noteable
          raise NoteableNotFoundError unless noteable

          noteable.unsubscribe(sent_notification.recipient)
        end

        def metrics_params
          super.merge(project: project&.full_path)
        end

        private

        def sent_notification
          @sent_notification ||= SentNotification.for(reply_key)
        end

        def reply_key
          mail_key.sub(Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX, '')
        end
      end
    end
  end
end
