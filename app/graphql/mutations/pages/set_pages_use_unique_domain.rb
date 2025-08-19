# frozen_string_literal: true

module Mutations
  module Pages
    class SetPagesUseUniqueDomain < Base
      graphql_name 'SetPagesUseUniqueDomain'

      argument :value, GraphQL::Types::Boolean,
        required: true,
        description: "Indicates user wants to use unique subdomains for their pages."

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: "Path of the project to set the pages to use unique domains."

      field :project, Types::ProjectType,
        null: true,
        description: "Project that was updated."

      authorize :admin_project

      def resolve(project_path:, value:)
        project = authorized_find!(project_path)

        return { project: project, errors: [] } if project.project_setting.update(pages_unique_domain_enabled: value)

        { project: nil, errors: errors_on_object(project) + errors_on_object(project.project_setting) }
      end
    end
  end
end
