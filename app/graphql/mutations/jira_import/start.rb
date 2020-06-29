# frozen_string_literal: true

module Mutations
  module JiraImport
    class Start < BaseMutation
      include ResolvesProject

      graphql_name 'JiraImportStart'

      field :jira_import,
            Types::JiraImportType,
            null: true,
            description: 'The Jira import data after mutation'

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The project to import the Jira project into'
      argument :jira_project_key, GraphQL::STRING_TYPE,
               required: true,
               description: 'Project key of the importer Jira project'
      argument :jira_project_name, GraphQL::STRING_TYPE,
               required: false,
               description: 'Project name of the importer Jira project'
      argument :users_mapping,
               [Types::JiraUsersMappingInputType],
               required: false,
               description: 'The mapping of Jira to GitLab users'

      def resolve(project_path:, jira_project_key:, users_mapping:)
        project = authorized_find!(full_path: project_path)
        mapping = users_mapping.to_ary.map { |map| map.to_hash }

        service_response = ::JiraImport::StartImportService
                             .new(context[:current_user], project, jira_project_key, mapping)
                             .execute
        jira_import = service_response.success? ? service_response.payload[:import_data] : nil

        {
          jira_import: jira_import,
          errors: service_response.errors
        }
      end

      private

      def find_object(full_path:)
        resolve_project(full_path: full_path)
      end

      def authorized_resource?(project)
        Ability.allowed?(context[:current_user], :admin_project, project)
      end
    end
  end
end
