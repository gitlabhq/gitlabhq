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

        delegate :project, to: :sent_notification, allow_nil: true
        delegate :noteable, to: :sent_notification

        def can_handle?
          mail_key =~ /\A\w+\z/
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

          reopen_issue_on_external_participant_note
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
          external_author = from_address if author == Users::Internal.support_bot

          sent_notification.create_reply(note_message, external_author)
        end

        def note_message
          return message unless sent_notification.noteable_type == "Issue"

          message_with_appended_reply
        end

        def from_address
          mail.from&.first
        end

        def validate_from_address!
          # Recipieint is always set to Support bot for ServiceDesk issues so we should exclude those.
          return if author == Users::Internal.support_bot

          raise UserNotFoundError unless from_address && author.verified_email?(from_address)
        end

        def reopen_issue_on_external_participant_note
          return unless noteable.respond_to?(:closed?)
          return unless noteable.closed?
          return unless author == Users::Internal.support_bot
          return unless project.service_desk_setting&.reopen_issue_on_external_participant_note?

          ::Notes::CreateService.new(
            project,
            Users::Internal.support_bot,
            noteable: noteable,
            note: build_reopen_message,
            confidential: true
          ).execute
        end

        def build_reopen_message
          translated_text = s_(
            "ServiceDesk|This issue has been reopened because it received a new comment from an external participant."
          )

          "#{assignees_references} :wave: #{translated_text}\n/reopen".lstrip
        end

        def assignees_references
          return unless noteable.assignees.any?

          noteable.assignees.map(&:to_reference).join(' ')
        end
      end
    end
  end
end
