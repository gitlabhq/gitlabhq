require 'gitlab/email/handler/base_handler'
require 'gitlab/email/handler/reply_processing'

module Gitlab
  module Email
    module Handler
      class CreateNoteHandler < BaseHandler
        include ReplyProcessing

        delegate :project, to: :sent_notification, allow_nil: true

        def can_handle?
          mail_key =~ /\A\w+\z/
        end

        def execute
          raise SentNotificationNotFoundError unless sent_notification

          validate_permission!(:create_note)

          raise NoteableNotFoundError unless sent_notification.noteable
          raise EmptyEmailError if message.blank?

          verify_record!(
            record: create_note,
            invalid_exception: InvalidNoteError,
            record_name: 'comment')
        end

        def metrics_params
          super.merge(project: project&.full_path)
        end

        private

        def author
          sent_notification.recipient
        end

        def sent_notification
          @sent_notification ||= SentNotification.for(mail_key)
        end

        def create_note
          sent_notification.create_reply(message)
        end

        def note_contains_only_quick_actions?(note)
          note.note.empty? && (note.quick_actions_commands.any? || note.quick_actions_results.any?)
        end

        def verify_record!(record:, invalid_exception:, record_name:)
          return if note_contains_only_quick_actions?(record)

          super
        end
      end
    end
  end
end
