# frozen_string_literal: true

module Resolvers
  module Projects
    class JiraProjectsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      argument :name,
               GraphQL::STRING_TYPE,
               required: false,
               description: 'Project name or key'

      def resolve(name: nil, **args)
        authorize!(project)

        response = jira_projects(name: name)

        if response.success?
          response.payload[:projects]
        else
          raise Gitlab::Graphql::Errors::BaseError, response.message
        end
      end

      def authorized_resource?(project)
        Ability.allowed?(context[:current_user], :admin_project, project)
      end

      private

      alias_method :jira_service, :object

      def project
        jira_service&.project
      end

      def jira_projects(name:)
        args = { query: name }.compact

        Jira::Requests::Projects::ListService.new(project.jira_service, args).execute
      end
    end
  end
end
