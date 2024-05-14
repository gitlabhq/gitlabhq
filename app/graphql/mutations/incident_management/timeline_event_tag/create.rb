# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module TimelineEventTag
      class Create < Base
        graphql_name 'TimelineEventTagCreate'

        include FindsProject

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project to create the timeline event tag in.'

        argument :name, GraphQL::Types::String,
          required: true,
          description: 'Name of the tag.'

        def resolve(project_path:, **args)
          project = authorized_find!(project_path)

          response ::IncidentManagement::TimelineEventTags::CreateService.new(
            project, current_user, args
          ).execute
        end
      end
    end
  end
end
