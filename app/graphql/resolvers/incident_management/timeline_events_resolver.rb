# frozen_string_literal: true

module Resolvers
  module IncidentManagement
    class TimelineEventsResolver < BaseResolver
      include LooksAhead

      alias_method :project, :object

      type ::Types::IncidentManagement::TimelineEventType.connection_type, null: true

      argument :incident_id,
        ::Types::GlobalIDType[::Issue],
        required: true,
        description: 'ID of the incident.'

      when_single do
        argument :id,
          ::Types::GlobalIDType[::IncidentManagement::TimelineEvent],
          required: true,
          description: 'ID of the timeline event.',
          prepare: ->(id, ctx) { id.model_id }
      end

      def resolve_with_lookahead(**args)
        incident = args[:incident_id].find
        raise GraphQL::ExecutionError, error_message if alert_is_disabled?(incident&.project)

        apply_lookahead(::IncidentManagement::TimelineEventsFinder.new(current_user, incident, args).execute)
      end

      def preloads
        {
          timeline_event_tags: [:timeline_event_tags]
        }
      end

      private

      def alert_is_disabled?(project)
        Feature.enabled?(:hide_incident_management_features, project)
      end

      def error_message
        "Field 'incidentManagementTimelineEvents' doesn't exist on type 'Project'."
      end
    end
  end
end
