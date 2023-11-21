# frozen_string_literal: true

module Mutations
  module Projects
    class Star < BaseMutation
      graphql_name 'StarProject'

      authorize :read_project

      argument :project_id,
        ::Types::GlobalIDType[::Project],
        required: true,
        description: 'Full path of the project to star or unstar.'

      argument :starred,
        GraphQL::Types::Boolean,
        required: true,
        description: 'Indicates whether to star or unstar the project.'

      field :count,
        GraphQL::Types::String,
        null: false,
        description: 'Number of stars for the project.'

      def resolve(project_id:, starred:)
        project = authorized_find!(id: project_id)

        if current_user.starred?(project) != starred
          current_user.toggle_star(project)
          project.reset
        end

        {
          count: project.star_count
        }
      end
    end
  end
end
