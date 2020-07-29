# frozen_string_literal: true

module Mutations
  module JiraImport
    class ImportUsers < BaseMutation
      include ResolvesProject

      graphql_name 'JiraImportUsers'

      field :jira_users,
            [Types::JiraUserType],
            null: true,
            description: 'Users returned from Jira, matched by email and name if possible.'

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The project to import the Jira users into'
      argument :start_at, GraphQL::INT_TYPE,
               required: false,
               description: 'The index of the record the import should started at, default 0 (50 records returned)'

      def resolve(project_path:, start_at: 0)
        project = authorized_find!(full_path: project_path)

        service_response = ::JiraImport::UsersImporter.new(context[:current_user], project, start_at.to_i).execute

        {
          jira_users: service_response.payload,
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
