# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module TimelineEventTag
      class Create < BaseMutation
        graphql_name 'TimelineEventTagCreate'

        include FindsProject

        authorize :create_timeline_event_tag
        authorize_granular_token permissions: :create_timeline_event_tag,
          boundary_argument: :project_path, boundary_type: :project

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project to create the timeline event tag in.'

        argument :name, GraphQL::Types::String,
          required: true,
          description: 'Name of the tag.'

        field :timeline_event_tag,
          ::Types::IncidentManagement::TimelineEventTagType,
          null: true,
          description: 'Timeline event tag.'

        def resolve(project_path:, **args)
          project = authorized_find!(project_path)

          result = ::IncidentManagement::TimelineEventTags::CreateService.new(
            project, current_user, args
          ).execute

          {
            timeline_event_tag: result.payload[:timeline_event_tag],
            errors: result.errors
          }
        end
      end
    end
  end
end
