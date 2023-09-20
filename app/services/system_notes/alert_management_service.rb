# frozen_string_literal: true

module SystemNotes
  class AlertManagementService < ::SystemNotes::BaseService
    # Called when the a new AlertManagement::Alert has been created
    #
    # alert - AlertManagement::Alert object.
    #
    # Example Note text:
    #
    #   "GitLab Alert Bot logged an alert from Prometheus"
    #
    # Returns the created Note object
    def create_new_alert(monitoring_tool)
      body = "logged an alert from **#{monitoring_tool}**"

      create_note(NoteSummary.new(noteable, project, Users::Internal.alert_bot, body, action: 'new_alert_added'))
    end

    # Called when the status of an AlertManagement::Alert has changed
    #
    # alert - AlertManagement::Alert object.
    #
    # Example Note text:
    #
    #   "changed the status to Acknowledged"
    #   "changed the status to Acknowledged by changing the incident status of #540"
    #
    # Returns the created Note object
    def change_alert_status(reason)
      status = noteable.state.to_s.titleize
      body = "changed the status to **#{status}**#{reason}"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'status'))
    end

    # Called when an issue is created based on an AlertManagement::Alert
    #
    # issue - Issue object.
    #
    # Example Note text:
    #
    #   "created incident #17 for this alert"
    #
    # Returns the created Note object
    def new_alert_issue(issue)
      body = "created incident #{issue.to_reference(project)} for this alert"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'alert_issue_added'))
    end

    # Called when an alert is resolved due to received resolving alert payload
    #
    # alert - AlertManagement::Alert object.
    #
    # Example Note text:
    #
    #   "changed the status to Resolved by closing issue #17"
    #
    # Returns the created Note object
    def log_resolving_alert(monitoring_tool)
      body = "logged a recovery alert from **#{monitoring_tool}**"

      create_note(NoteSummary.new(noteable, project, Users::Internal.alert_bot, body, action: 'new_alert_added'))
    end
  end
end
