# frozen_string_literal: true

module Mutations
  module Pages
    class SetPagesForceHttps < Base
      graphql_name 'SetPagesForceHttps'

      argument :value,
        GraphQL::Types::Boolean,
        required: true,
        description: "Indicates user wants to enforce HTTPS on their pages."

      argument :project_path,
        GraphQL::Types::ID,
        required: true,
        description: "Path of the project to set the pages force HTTPS."

      field :project,
        Types::ProjectType,
        null: true,
        description: "Project that was updated."

      authorize :admin_project

      def resolve(project_path:, value:)
        project = authorized_find!(project_path)

        return { project: project, errors: [] } if project.update(pages_https_only: value)

        { project: nil, errors: errors_on_object(project) }
      end
    end
  end
end
