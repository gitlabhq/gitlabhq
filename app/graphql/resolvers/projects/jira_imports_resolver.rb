# frozen_string_literal: true

module Resolvers
  module Projects
    class JiraImportsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      alias_method :project, :object

      def resolve(**args)
        authorize!(project)

        project.jira_imports
      end

      def authorized_resource?(project)
        return false unless Feature.enabled?(:jira_issue_import, project)

        Ability.allowed?(context[:current_user], :admin_project, project)
      end
    end
  end
end
