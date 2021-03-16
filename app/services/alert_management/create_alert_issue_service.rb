# frozen_string_literal: true

module AlertManagement
  class CreateAlertIssueService
    include Gitlab::Utils::StrongMemoize

    DEFAULT_ALERT_TITLE = ::Gitlab::AlertManagement::Payload::Generic::DEFAULT_TITLE
    DEFAULT_INCIDENT_TITLE = 'New: Incident'

    # @param alert [AlertManagement::Alert]
    # @param user [User]
    def initialize(alert, user)
      @alert = alert
      @user = user
    end

    def execute
      return error_no_permissions unless allowed?
      return error_issue_already_exists if alert.issue

      result = create_incident
      return result unless result.success?

      issue = result.payload[:issue]
      return error(object_errors(alert), issue) unless associate_alert_with_issue(issue)

      update_title_for(issue)

      SystemNoteService.new_alert_issue(alert, issue, user)

      result
    end

    private

    attr_reader :alert, :user

    delegate :project, to: :alert

    def allowed?
      user.can?(:create_issue, project)
    end

    def create_incident
      ::IncidentManagement::Incidents::CreateService.new(
        project,
        user,
        title: alert_presenter.title,
        description: alert_presenter.issue_description,
        severity: alert.severity
      ).execute
    end

    def associate_alert_with_issue(issue)
      alert.update(issue_id: issue.id)
    end

    def update_title_for(issue)
      return unless issue.title == DEFAULT_ALERT_TITLE

      issue.update!(title: "#{DEFAULT_INCIDENT_TITLE} #{issue.iid}")
    end

    def error(message, issue = nil)
      ServiceResponse.error(payload: { issue: issue }, message: message)
    end

    def error_issue_already_exists
      error(_('An issue already exists'))
    end

    def error_no_permissions
      error(_('You have no permissions'))
    end

    def alert_presenter
      strong_memoize(:alert_presenter) do
        alert.present
      end
    end

    def object_errors(object)
      object.errors.full_messages.to_sentence
    end
  end
end
