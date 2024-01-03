# frozen_string_literal: true

module IssueEmailParticipants
  class BaseService < ::BaseProjectService
    MAX_NUMBER_OF_EMAILS = 6

    attr_reader :target, :emails

    def initialize(target:, current_user:, emails:)
      super(project: target.project, current_user: current_user)

      @target = target
      @emails = emails
    end

    private

    def response_from_guard_checks
      return error_feature_flag unless Feature.enabled?(:issue_email_participants, target.project)
      return error_underprivileged unless current_user.can?(:"admin_#{target.to_ability_name}", target)

      nil
    end

    def add_system_note(emails)
      message = format(system_note_text, emails: emails.to_sentence)
      ::SystemNoteService.email_participants(target, project, current_user, message)

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
      error(_("You don't have permission to manage email participants."))
    end
  end
end
