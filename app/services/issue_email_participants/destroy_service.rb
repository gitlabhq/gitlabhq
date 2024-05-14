# frozen_string_literal: true

module IssueEmailParticipants
  class DestroyService < BaseService
    def execute
      return error_underprivileged unless user_privileged?
      return error_no_participants_removed unless emails.present?

      removed_emails = remove_participants(emails.first(MAX_NUMBER_OF_EMAILS))

      if removed_emails.any?
        message = add_system_note(removed_emails, user: system_note_author)
        ServiceResponse.success(message: message.upcase_first << ".")
      else
        error_no_participants_removed
      end
    end

    private

    def remove_participants(emails_to_remove)
      participants = target
        .issue_email_participants
        .with_emails(emails_to_remove)
        .load # to avoid additional query

      emails = participants.map(&:email)
      return [] if emails.empty?

      participants.delete_all

      emails
    end

    def system_note_text
      return system_note_unsubscribe_text if unsubscribe_context?

      _("removed %{emails}")
    end

    def system_note_unsubscribe_text
      _("unsubscribed %{emails}")
    end

    def system_note_author
      Users::Internal.support_bot if unsubscribe_context?
    end

    def unsubscribe_context?
      options[:context] == :unsubscribe
    end

    def error_no_participants_removed
      error(_("No email participants were removed. Either none were provided, or they don't exist."))
    end
  end
end
