# frozen_string_literal: true

module IssueEmailParticipants
  class CreateService < BaseService
    include Gitlab::Utils::StrongMemoize

    MAX_NUMBER_OF_RECORDS = 10

    def execute
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

      # Charge the limiter with the number of records that can actually be
      # created under MAX_NUMBER_OF_RECORDS, not emails_to_add.size, so a
      # request adding more addresses than remaining slots doesn't
      # over-consume budget. A create failure inside the loop below can
      # still overcount by one record (rare, errs toward over-throttling).
      creatable_count = [emails_to_add.size, MAX_NUMBER_OF_RECORDS - existing_emails_count].min
      rate_limited = rate_limiter.rate_limit_batch!(creatable_count) if creatable_count > 0

      emails_to_add.each do |email|
        if existing_emails_count >= MAX_NUMBER_OF_RECORDS
          log_above_limit_count(emails_to_add.size - added_emails.size)

          break
        end

        new_participant = target.issue_email_participants.create(email: email)
        next unless new_participant.persisted?

        added_emails << email
        existing_emails_count += 1

        next if rate_limited

        Notify.service_desk_new_participant_email(target.id, new_participant).deliver_later
        Gitlab::Metrics::BackgroundTransaction.current&.add_event(:service_desk_new_participant_email)
      end

      rate_limiter.post_suppression_notice(target) if rate_limited && added_emails.any?

      added_emails
    end

    def rate_limiter
      ::ServiceDesk::EmailRateLimiter.new(project)
    end
    strong_memoize_attr :rate_limiter

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
