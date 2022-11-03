# frozen_string_literal: true

module IncidentManagement
  module TimelineEvents
    # @param timeline_event [IncidentManagement::TimelineEvent]
    # @param user [User]
    # @param params [Hash]
    # @option params [string] note
    # @option params [datetime] occurred_at
    class UpdateService < TimelineEvents::BaseService
      VALIDATION_CONTEXT = :user_input

      def initialize(timeline_event, user, params)
        @timeline_event = timeline_event
        @incident = timeline_event.incident
        @user = user
        @note = params[:note]
        @occurred_at = params[:occurred_at]
        @validation_context = VALIDATION_CONTEXT
      end

      def execute
        return error_no_permissions unless allowed?

        timeline_event.assign_attributes(update_params)

        if timeline_event.save(context: validation_context)
          add_system_note(timeline_event)

          track_usage_event(:incident_management_timeline_event_edited, user.id)
          success(timeline_event)
        else
          error_in_save(timeline_event)
        end
      end

      private

      attr_reader :timeline_event, :incident, :user, :note, :occurred_at, :validation_context

      def update_params
        { updated_by_user: user, note: note, occurred_at: occurred_at }.compact
      end

      def add_system_note(timeline_event)
        changes = was_changed(timeline_event)
        return if changes == :none

        SystemNoteService.edit_timeline_event(timeline_event, user, was_changed: changes)
      end

      def was_changed(timeline_event)
        changes = timeline_event.previous_changes
        occurred_at_changed = changes.key?('occurred_at')
        note_changed = changes.key?('note')

        return :occurred_at_and_note if occurred_at_changed && note_changed
        return :occurred_at if occurred_at_changed
        return :note if note_changed

        :none
      end

      def allowed?
        user&.can?(:edit_incident_management_timeline_event, timeline_event)
      end
    end
  end
end
