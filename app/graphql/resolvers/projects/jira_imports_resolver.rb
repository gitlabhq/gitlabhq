# frozen_string_literal: true

module Resolvers
  module Projects
    class JiraImportsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      alias_method :project, :object

      def resolve(**args)
        return JiraImportData.none unless project&.import_data.present?

        authorize!(project)

        project.import_data.becomes(JiraImportData).projects
      end

      def authorized_resource?(project)
        return false unless Feature.enabled?(:jira_issue_import, project)

        Ability.allowed?(context[:current_user], :admin_project, project)
      end
    end
  end
end
