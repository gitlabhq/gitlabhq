# frozen_string_literal: true

module Mutations
  module JiraImport
    class Start < BaseMutation
      graphql_name 'JiraImportStart'

      include FindsProject

      authorize :admin_project

      field :jira_import,
        Types::JiraImportType,
        null: true,
        description: 'Jira import data after mutation.'

      argument :jira_project_key, GraphQL::Types::String,
        required: true,
        description: 'Project key of the importer Jira project.'
      argument :jira_project_name, GraphQL::Types::String,
        required: false,
        description: 'Project name of the importer Jira project.',
        deprecated: { milestone: '17.4', reason: 'Argument is not used' }
      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Project to import the Jira project into.'
      argument :users_mapping,
        [Types::JiraUsersMappingInputType],
        required: false,
        description: 'Mapping of Jira to GitLab users.'

      def resolve(project_path:, jira_project_key:, users_mapping:) # rubocop: disable GraphQL/UnusedArgument -- `jira_project_name` must be deprecated before we can remove it
        project = authorized_find!(project_path)
        mapping = users_mapping.to_ary.map(&:to_hash)

        service_response = ::JiraImport::StartImportService
                             .new(context[:current_user], project, jira_project_key, mapping)
                             .execute
        jira_import = service_response.success? ? service_response.payload[:import_data] : nil

        {
          jira_import: jira_import,
          errors: service_response.errors
        }
      end
    end
  end
end
