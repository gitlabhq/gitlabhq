# frozen_string_literal: true

module SystemNotes
  class IncidentService < ::SystemNotes::BaseService
    # Called when the severity of an Incident has changed
    #
    # Example Note text:
    #
    #   "changed the severity to Medium - S3"
    #
    # Returns the created Note object
    def change_incident_severity
      severity = noteable.severity

      if severity_label = IssuableSeverity::SEVERITY_LABELS[severity.to_sym]
        body = "changed the severity to **#{severity_label}**"

        create_note(NoteSummary.new(noteable, project, author, body, action: 'severity'))
      else
        Gitlab::AppLogger.error(
          message: 'Cannot create a system note for severity change',
          noteable_class: noteable.class.to_s,
          noteable_id: noteable.id,
          severity: severity
        )
      end
    end

    # Called when the status of an IncidentManagement::IssuableEscalationStatus has changed
    #
    # reason - String.
    #
    # Example Note text:
    #
    #   "changed the incident status to Acknowledged"
    #   "changed the incident status to Acknowledged by changing the status of ^alert#540"
    #
    # Returns the created Note object
    def change_incident_status(reason)
      status = noteable.escalation_status.status_name.to_s.titleize
      body = "changed the incident status to **#{status}**#{reason}"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'status'))
    end
  end
end
