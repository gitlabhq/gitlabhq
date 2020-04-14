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
        return false unless project.jira_issues_import_feature_flag_enabled?

        context[:current_user].present? && Ability.allowed?(context[:current_user], :read_project, project)
      end
    end
  end
end
