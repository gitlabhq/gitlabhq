# frozen_string_literal: true

require 'gitlab/email/handler/base_handler'
require 'gitlab/email/handler/reply_processing'

# handles note/reply creation emails with these formats:
#   incoming+1234567890abcdef1234567890abcdef@incoming.gitlab.com
# Quoted material is _not_ stripped but appended as a `details` section
module Gitlab
  module Email
    module Handler
      class CreateNoteHandler < BaseHandler
        include ReplyProcessing

        HANDLER_REGEX = /\A#{::SentNotification::FULL_REPLY_KEY_REGEX}\z/

        delegate :project, to: :sent_notification, allow_nil: true
        delegate :noteable, to: :sent_notification

        def can_handle?
          mail_key =~ HANDLER_REGEX
        end

        def execute
          raise SentNotificationNotFoundError unless sent_notification

          validate_permission!(:create_note)

          validate_from_address!

          raise NoteableNotFoundError unless noteable
          raise EmptyEmailError if note_message.blank?

          verify_record!(
            record: create_note,
            invalid_exception: InvalidNoteError,
            record_name: 'comment')

          return unless project

          reopen_issue_on_external_participant_note(
            noteable: noteable,
            author: author,
            project: project,
            support_bot: support_bot
          )
        end

        def metrics_event
          :receive_email_create_note
        end

        private

        def author
          sent_notification.recipient
        end

        def sent_notification
          @sent_notification ||= SentNotification.for(mail_key)
        end

        def create_note
          sent_notification.create_reply(note_message, external_author)
        end

        def note_message
          return message unless sent_notification.noteable_type == "Issue"

          message_with_appended_reply
        end

        def validate_from_address!
          # Recipieint is always set to Support bot for ServiceDesk issues so we should exclude those.
          return if author.support_bot?

          raise UserNotFoundError unless from_address && author.verified_email?(from_address)
        end

        def external_author
          return unless author.support_bot?

          from_address
        end

        def support_bot
          return unless project

          Users::Internal.in_organization(project.organization_id).support_bot
        end
      end
    end
  end
end
