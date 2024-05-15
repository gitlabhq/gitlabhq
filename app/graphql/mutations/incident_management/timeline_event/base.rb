# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module TimelineEvent
      class Base < BaseMutation
        field :timeline_event,
          ::Types::IncidentManagement::TimelineEventType,
          null: true,
          description: 'Timeline event.'

        authorize :admin_incident_management_timeline_event

        private

        def response(result)
          {
            timeline_event: result.payload[:timeline_event],
            errors: result.errors
          }
        end

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::IncidentManagement::TimelineEvent).sync
        end
      end
    end
  end
end
