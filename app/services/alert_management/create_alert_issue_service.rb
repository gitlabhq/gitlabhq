# frozen_string_literal: true

module AlertManagement
  class CreateAlertIssueService
    # @param alert [AlertManagement::Alert]
    # @param user [User]
    def initialize(alert, user)
      @alert = alert
      @user = user
    end

    def execute
      return error_no_permissions unless allowed?
      return error_issue_already_exists if alert.issue

      result = create_issue(alert, user, alert_payload)
      @issue = result[:issue]

      return error(result[:message]) if result[:status] == :error
      return error(alert.errors.full_messages.to_sentence) unless update_alert_issue_id

      success
    end

    private

    attr_reader :alert, :user, :issue

    delegate :project, to: :alert

    def allowed?
      user.can?(:create_issue, project)
    end

    def create_issue(alert, user, alert_payload)
      ::IncidentManagement::CreateIssueService
        .new(project, alert_payload, user)
        .execute(skip_settings_check: true)
    end

    def alert_payload
      if alert.prometheus?
        alert.payload
      else
        Gitlab::Alerting::NotificationPayloadParser.call(alert.payload.to_h)
      end
    end

    def update_alert_issue_id
      alert.update(issue_id: issue.id)
    end

    def success
      ServiceResponse.success(payload: { issue: issue })
    end

    def error(message)
      ServiceResponse.error(payload: { issue: issue }, message: message)
    end

    def error_issue_already_exists
      error(_('An issue already exists'))
    end

    def error_no_permissions
      error(_('You have no permissions'))
    end
  end
end
