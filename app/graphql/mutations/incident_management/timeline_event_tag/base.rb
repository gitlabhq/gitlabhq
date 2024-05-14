# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module TimelineEventTag
      class Base < BaseMutation
        field :timeline_event_tag,
          ::Types::IncidentManagement::TimelineEventTagType,
          null: true,
          description: 'Timeline event tag.'

        authorize :admin_incident_management_timeline_event_tag

        private

        def response(result)
          {
            timeline_event_tag: result.payload[:timeline_event_tag],
            errors: result.errors
          }
        end
      end
    end
  end
end
