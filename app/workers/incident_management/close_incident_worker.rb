# frozen_string_literal: true

module IncidentManagement
  class CloseIncidentWorker
    include ApplicationWorker

    idempotent!
    deduplicate :until_executed
    data_consistency :always
    feature_category :incident_management
    urgency :low

    # Issues:CloseService execute webhooks which are treated as external dependencies
    worker_has_external_dependencies!

    def perform(issue_id)
      incident = Issue.with_issue_type(:incident).opened.find_by_id(issue_id)

      return unless incident

      close_incident(incident)
      add_system_note(incident)
    end

    private

    def user(incident)
      alert_bot_for_organization_id(incident.project.organization_id)
    end

    def alert_bot_for_organization_id(organization_id)
      @alert_bots ||= {}
      @alert_bots[organization_id] ||= Users::Internal.in_organization(organization_id).alert_bot
    end

    def close_incident(incident)
      ::Issues::CloseService
        .new(container: incident.project, current_user: user(incident))
        .execute(incident, system_note: false)
    end

    def add_system_note(incident)
      return unless incident.reset.closed?

      SystemNoteService.auto_resolve_prometheus_alert(incident, incident.project, user(incident))
    end
  end
end
