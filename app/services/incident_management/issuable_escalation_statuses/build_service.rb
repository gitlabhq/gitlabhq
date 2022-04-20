# frozen_string_literal: true

module IncidentManagement
  module IssuableEscalationStatuses
    class BuildService < ::BaseProjectService
      def initialize(issue)
        @issue = issue
        @alert = issue.alert_management_alert

        super(project: issue.project)
      end

      def execute
        return issue.escalation_status if issue.escalation_status

        issue.build_incident_management_issuable_escalation_status(alert_params)
      end

      private

      attr_reader :issue, :alert

      def alert_params
        return {} unless alert

        {
          status_event: alert.status_event_for(alert.status_name)
        }
      end
    end
  end
end

IncidentManagement::IssuableEscalationStatuses::BuildService.prepend_mod
