# frozen_string_literal: true

module IssueEmailParticipants
  class CreateService < BaseService
    include Gitlab::Utils::StrongMemoize

    MAX_NUMBER_OF_RECORDS = 10

    def execute
      return error_feature_flag unless Feature.enabled?(:issue_email_participants, target.project)
      return error_underprivileged unless user_privileged?
      return error_no_participants_added unless emails.present?

      added_emails = add_participants(deduplicate_and_limit_emails)

      if added_emails.any?
        message = add_system_note(added_emails)
        ServiceResponse.success(message: message.upcase_first << ".")
      else
        error_no_participants_added
      end
    end

    private

    def deduplicate_and_limit_emails
      # Compare downcase versions, but use the original email
      emails.index_by { |email| [email.downcase, email] }.excluding(*existing_emails).each_value
        .first(MAX_NUMBER_OF_EMAILS)
    end

    def add_participants(emails_to_add)
      existing_emails_count = existing_emails.size
      added_emails = []

      emails_to_add.each do |email|
        if existing_emails_count >= MAX_NUMBER_OF_RECORDS
          log_above_limit_count(emails_to_add.size - added_emails.size)

          return added_emails
        end

        new_participant = target.issue_email_participants.create(email: email)
        next unless new_participant.persisted?

        added_emails << email
        existing_emails_count += 1

        Notify.service_desk_new_participant_email(target.id, new_participant).deliver_later
        Gitlab::Metrics::BackgroundTransaction.current&.add_event(:service_desk_new_participant_email)
      end

      added_emails
    end

    def existing_emails
      target.email_participants_emails_downcase
    end
    strong_memoize_attr :existing_emails

    def log_above_limit_count(above_limit_count)
      Gitlab::ApplicationContext.with_context(related_class: self.class.to_s, user: current_user, project: project) do
        Gitlab::AppLogger.info({ above_limit_count: above_limit_count })
      end
    end

    def system_note_text
      _("added %{emails}")
    end

    def error_no_participants_added
      error(_("No email participants were added. Either none were provided, or they already exist."))
    end
  end
end
