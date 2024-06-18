# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module TimelineEvent
      class Create < Base
        graphql_name 'TimelineEventCreate'

        argument :incident_id, Types::GlobalIDType[::Issue],
          required: true,
          description: 'Incident ID of the timeline event.'

        argument :note, GraphQL::Types::String,
          required: true,
          description: 'Text note of the timeline event.'

        argument :occurred_at, Types::TimeType,
          required: true,
          description: 'Timestamp of when the event occurred.'

        argument :timeline_event_tag_names, [GraphQL::Types::String],
          required: false,
          description: copy_field_description(Types::IncidentManagement::TimelineEventType, :timeline_event_tags)

        def resolve(incident_id:, **args)
          incident = authorized_find!(id: incident_id)

          authorize!(incident)

          response ::IncidentManagement::TimelineEvents::CreateService.new(
            incident, current_user, args.merge(editable: true)
          ).execute
        end

        private

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::Issue).sync
        end
      end
    end
  end
end
