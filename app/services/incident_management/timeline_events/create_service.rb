# frozen_string_literal: true

module IncidentManagement
  module TimelineEvents
    DEFAULT_ACTION = 'comment'
    DEFAULT_EDITABLE = false
    DEFAULT_AUTO_CREATED = false

    class CreateService < TimelineEvents::BaseService
      def initialize(incident, user, params)
        @project = incident.project
        @incident = incident
        @user = user
        @params = params
        @auto_created = !!params.fetch(:auto_created, DEFAULT_AUTO_CREATED)
      end

      class << self
        def create_incident(incident, user)
          note = "@#{user.username} created the incident"
          occurred_at = incident.created_at
          action = 'issues'

          new(incident, user, note: note, occurred_at: occurred_at, action: action, auto_created: true).execute
        end

        def reopen_incident(incident, user)
          note = "@#{user.username} reopened the incident"
          occurred_at = incident.updated_at
          action = 'issues'

          new(incident, user, note: note, occurred_at: occurred_at, action: action, auto_created: true).execute
        end

        def resolve_incident(incident, user)
          note = "@#{user.username} resolved the incident"
          occurred_at = incident.updated_at
          action = 'status'

          new(incident, user, note: note, occurred_at: occurred_at, action: action, auto_created: true).execute
        end

        def change_incident_status(incident, user, escalation_status)
          status = escalation_status.status_name.to_s.titleize
          note = "@#{user.username} changed the incident status to **#{status}**"
          occurred_at = incident.updated_at
          action = 'status'

          new(incident, user, note: note, occurred_at: occurred_at, action: action, auto_created: true).execute
        end

        def change_severity(incident, user)
          severity_label = IssuableSeverity::SEVERITY_LABELS[incident.severity.to_sym]
          note = "@#{user.username} changed the incident severity to **#{severity_label}**"
          occurred_at = incident.updated_at
          action = 'severity'

          new(incident, user, note: note, occurred_at: occurred_at, action: action, auto_created: true).execute
        end

        def change_labels(incident, user, added_labels: [], removed_labels: [])
          return if Feature.disabled?(:incident_timeline_events_from_labels, incident.project)

          if added_labels.blank? && removed_labels.blank?
            return ServiceResponse.error(message: _('There are no changed labels'))
          end

          labels_note = ->(verb, labels) {
            "#{verb} #{labels.map(&:to_reference).join(' ')} #{'label'.pluralize(labels.count)}" if labels.present?
          }

          added_note = labels_note.call('added', added_labels)
          removed_note = labels_note.call('removed', removed_labels)
          note = "@#{user.username} #{[added_note, removed_note].compact.join(' and ')}"
          occurred_at = incident.updated_at
          action = 'label'

          new(incident, user, note: note, occurred_at: occurred_at, action: action, auto_created: true).execute
        end
      end

      def execute
        return error_no_permissions unless allowed?

        timeline_event_params = {
          project: project,
          incident: incident,
          author: user,
          note: params[:note],
          action: params.fetch(:action, DEFAULT_ACTION),
          note_html: params[:note_html].presence || params[:note],
          occurred_at: params[:occurred_at],
          promoted_from_note: params[:promoted_from_note],
          editable: params.fetch(:editable, DEFAULT_EDITABLE)
        }

        non_existing_tags = validate_tags(project, params[:timeline_event_tag_names])

        return error("#{_("Following tags don't exist")}: #{non_existing_tags}") unless non_existing_tags.empty?

        timeline_event = IncidentManagement::TimelineEvent.new(timeline_event_params)

        if timeline_event.save(context: validation_context)
          add_system_note(timeline_event)

          create_timeline_event_tag_links(timeline_event, params[:timeline_event_tag_names])

          track_timeline_event("incident_management_timeline_event_created", project)

          success(timeline_event)
        else
          error_in_save(timeline_event)
        end
      end

      private

      attr_reader :project, :user, :incident, :params, :auto_created

      def allowed?
        return true if auto_created

        super
      end

      def add_system_note(timeline_event)
        return if auto_created

        SystemNoteService.add_timeline_event(timeline_event)
      end

      def validation_context
        :user_input if !auto_created && params[:promoted_from_note].blank?
      end

      def create_timeline_event_tag_links(timeline_event, tag_names)
        return unless tag_names&.any?

        auto_create_predefined_tags(tag_names)

        # Refetches the tag objects to consider predefined tags as well
        tags = project.incident_management_timeline_event_tags.by_names(tag_names)

        tag_links = tags.select(:id).map do |tag|
          {
            timeline_event_id: timeline_event.id,
            timeline_event_tag_id: tag.id,
            created_at: DateTime.current
          }
        end

        IncidentManagement::TimelineEventTagLink.insert_all(tag_links) if tag_links.any?
      end

      def validate_tags(project, tag_names)
        return [] unless tag_names&.any?

        predefined_tags = TimelineEventTag::PREDEFINED_TAGS.map(&:downcase)

        tag_names_downcased = tag_names.map(&:downcase)

        tags = project.incident_management_timeline_event_tags.by_names(tag_names).pluck_names.map(&:downcase)

        # remove tags from given tag_names and also remove predefined tags which can be auto created
        tag_names_downcased - tags - predefined_tags
      end
    end
  end
end
