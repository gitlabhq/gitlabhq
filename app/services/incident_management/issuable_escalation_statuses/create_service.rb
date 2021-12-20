# frozen_string_literal: true

module IncidentManagement
  module IssuableEscalationStatuses
    class CreateService < BaseService
      def initialize(issue)
        @issue = issue
        @alert = issue.alert_management_alert
      end

      def execute
        escalation_status = ::IncidentManagement::IssuableEscalationStatus.new(issue: issue, **alert_params)

        if escalation_status.save
          ServiceResponse.success(payload: { escalation_status: escalation_status })
        else
          ServiceResponse.error(message: escalation_status.errors&.full_messages)
        end
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

IncidentManagement::IssuableEscalationStatuses::CreateService.prepend_mod
