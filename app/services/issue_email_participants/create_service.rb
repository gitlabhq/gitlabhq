# frozen_string_literal: true

module IssueEmailParticipants
  class CreateService < ::BaseProjectService
    MAX_NUMBER_OF_EMAILS = 6

    attr_reader :target, :emails

    def initialize(target:, current_user:, emails:)
      super(project: target.project, current_user: current_user)

      @target = target
      @emails = emails
    end

    def execute
      return error_feature_flag unless Feature.enabled?(:issue_email_participants, target.project)
      return error_underprivileged unless current_user.can?(:"admin_#{target.to_ability_name}", target)
      return error_no_participants unless emails.present?

      added_emails = add_participants(deduplicate_and_limit_emails)

      if added_emails.any?
        message = add_system_note(added_emails)
        ServiceResponse.success(message: message.upcase_first << ".")
      else
        error_no_participants
      end
    end

    private

    def deduplicate_and_limit_emails
      existing_emails = target.email_participants_emails_downcase
      # Compare downcase versions, but use the original email
      emails.index_by { |email| [email.downcase, email] }.excluding(*existing_emails).each_value
        .first(MAX_NUMBER_OF_EMAILS)
    end

    def add_participants(emails_to_add)
      added_emails = []
      emails_to_add.each do |email|
        new_participant = target.issue_email_participants.create(email: email)
        added_emails << email if new_participant.persisted?
      end

      added_emails
    end

    def add_system_note(added_emails)
      message = format(_("added %{emails}"), emails: added_emails.to_sentence)
      ::SystemNoteService.add_email_participants(target, project, current_user, message)

      message
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def error_feature_flag
      # Don't translate feature flag error because it's temporary.
      error("Feature flag issue_email_participants is not enabled for this project.")
    end

    def error_underprivileged
      error(_("You don't have permission to add email participants."))
    end

    def error_no_participants
      error(_("No email participants were added. Either none were provided, or they already exist."))
    end
  end
end
