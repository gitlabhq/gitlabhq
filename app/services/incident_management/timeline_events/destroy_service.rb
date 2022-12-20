# frozen_string_literal: true

module IncidentManagement
  module TimelineEvents
    class DestroyService < TimelineEvents::BaseService
      # @param timeline_event [IncidentManagement::TimelineEvent]
      # @param user [User]
      def initialize(timeline_event, user)
        @timeline_event = timeline_event
        @user = user
        @incident = timeline_event.incident
        @project = @incident.project
      end

      def execute
        return error_no_permissions unless allowed?

        if timeline_event.destroy
          add_system_note(incident, user)

          track_timeline_event('incident_management_timeline_event_deleted', project)
          success(timeline_event)
        else
          error_in_save(timeline_event)
        end
      end

      private

      attr_reader :project, :timeline_event, :user, :incident

      def add_system_note(incident, user)
        SystemNoteService.delete_timeline_event(incident, user)
      end
    end
  end
end
