# frozen_string_literal: true

module IncidentManagement
  module IssuableEscalationStatuses
    class AfterUpdateService < ::BaseProjectService
      def initialize(issuable, current_user)
        @issuable = issuable
        @escalation_status = issuable.escalation_status
        @alert = issuable.alert_management_alert

        super(project: issuable.project, current_user: current_user)
      end

      def execute
        after_update

        ServiceResponse.success(payload: { escalation_status: escalation_status })
      end

      private

      attr_reader :issuable, :escalation_status, :alert

      def after_update
        sync_to_alert
      end

      def sync_to_alert
        return unless alert
        return if alert.status == escalation_status.status

        ::AlertManagement::Alerts::UpdateService.new(
          alert,
          current_user,
          status: escalation_status.status_name
        ).execute
      end
    end
  end
end

::IncidentManagement::IssuableEscalationStatuses::AfterUpdateService.prepend_mod
