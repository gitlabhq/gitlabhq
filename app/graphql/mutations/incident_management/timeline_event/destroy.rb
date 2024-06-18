# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module TimelineEvent
      class Destroy < Base
        graphql_name 'TimelineEventDestroy'

        argument :id, Types::GlobalIDType[::IncidentManagement::TimelineEvent],
          required: true,
          description: 'Timeline event ID to remove.'

        def resolve(id:)
          timeline_event = authorized_find!(id: id)

          response ::IncidentManagement::TimelineEvents::DestroyService.new(
            timeline_event,
            current_user
          ).execute
        end
      end
    end
  end
end
