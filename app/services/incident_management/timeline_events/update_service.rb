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
        @project = incident.project
        @user = user
        @note = params[:note]
        @occurred_at = params[:occurred_at]
        @validation_context = VALIDATION_CONTEXT
        @timeline_event_tags = params[:timeline_event_tag_names]
      end

      def execute
        return error_no_permissions unless allowed?

        unless timeline_event_tags.nil?
          auto_create_predefined_tags(timeline_event_tags)

          # Refetches the tag objects to consider predefined tags as well
          new_tags = timeline_event
                      .project
                      .incident_management_timeline_event_tags
                      .by_names(timeline_event_tags)

          non_existing_tags = validate_tags(new_tags)

          return error("#{_("Following tags don't exist")}: #{non_existing_tags}") if non_existing_tags.any?
        end

        begin
          timeline_event_saved = update_timeline_event_and_event_tags(new_tags)
        rescue ActiveRecord::RecordInvalid
          error_in_save(timeline_event)
        end

        if timeline_event_saved
          add_system_note(timeline_event)

          track_timeline_event('incident_management_timeline_event_edited', timeline_event.project)
          success(timeline_event)
        else
          error_in_save(timeline_event)
        end
      end

      private

      attr_reader :timeline_event, :incident, :project, :user,
        :note, :occurred_at, :validation_context, :timeline_event_tags

      def update_timeline_event_and_event_tags(new_tags)
        ApplicationRecord.transaction do
          timeline_event.timeline_event_tags = new_tags unless timeline_event_tags.nil?

          timeline_event.assign_attributes(update_params)

          timeline_event.save!(context: validation_context)
        end
      end

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

      def validate_tags(new_tags)
        timeline_event_tags.map(&:downcase) - new_tags.map(&:name).map(&:downcase)
      end

      def allowed?
        user&.can?(:edit_incident_management_timeline_event, timeline_event)
      end
    end
  end
end
