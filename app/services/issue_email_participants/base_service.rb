# frozen_string_literal: true

module IssueEmailParticipants
  class BaseService < ::BaseProjectService
    MAX_NUMBER_OF_EMAILS = 6

    attr_reader :target, :emails, :options

    def initialize(target:, current_user:, emails:, options: {})
      super(project: target.project, current_user: current_user)

      @target = target
      @emails = emails
      @options = options
    end

    private

    def add_system_note(emails, user: nil)
      return unless emails.present?

      message = format(system_note_text, emails: emails.to_sentence)
      ::SystemNoteService.email_participants(target, project, (user || current_user), message)

      message
    end

    def user_privileged?
      current_user&.can?(:"admin_#{target.to_ability_name}", target) || skip_permission_check?
    end

    def skip_permission_check?
      options[:skip_permission_check] == true
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
