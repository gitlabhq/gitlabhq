# frozen_string_literal: true

module IncidentManagement
  module IssuableEscalationStatuses
    class AfterUpdateService < ::BaseProjectService
      def initialize(issuable, current_user, **params)
        @issuable = issuable
        @escalation_status = issuable.escalation_status

        super(project: issuable.project, current_user: current_user, params: params)
      end

      def execute
        after_update

        ServiceResponse.success(payload: { escalation_status: escalation_status })
      end

      private

      attr_reader :issuable, :escalation_status

      def after_update
        add_status_system_note
        add_timeline_event
      end

      def add_status_system_note
        return unless escalation_status.status_previously_changed?

        SystemNoteService.change_incident_status(issuable, current_user, params[:status_change_reason])
      end

      def add_timeline_event
        return unless escalation_status.status_previously_changed?

        IncidentManagement::TimelineEvents::CreateService
          .change_incident_status(issuable, current_user, escalation_status)
      end
    end
  end
end

::IncidentManagement::IssuableEscalationStatuses::AfterUpdateService.prepend_mod
