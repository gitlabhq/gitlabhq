# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module TimelineEvent
      class Update < Base
        graphql_name 'TimelineEventUpdate'

        argument :id, ::Types::GlobalIDType[::IncidentManagement::TimelineEvent],
          required: true,
          description: 'ID of the timeline event to update.'

        argument :note, GraphQL::Types::String,
          required: false,
          description: 'Text note of the timeline event.'

        argument :occurred_at, Types::TimeType,
          required: false,
          description: 'Timestamp when the event occurred.'

        argument :timeline_event_tag_names, [GraphQL::Types::String],
          required: false,
          description: copy_field_description(Types::IncidentManagement::TimelineEventType, :timeline_event_tags)

        def resolve(id:, **args)
          timeline_event = authorized_find!(id: id)

          response ::IncidentManagement::TimelineEvents::UpdateService.new(
            timeline_event,
            current_user,
            args
          ).execute
        end
      end
    end
  end
end
