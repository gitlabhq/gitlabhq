# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module TimelineEvent
      class Destroy < Base
        graphql_name 'TimelineEventDestroy'

        authorize_granular_token permissions: :delete_timeline_event,
          boundary_argument: :id, boundary: :project, boundary_type: :project

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
