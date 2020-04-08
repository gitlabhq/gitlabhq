# frozen_string_literal: true

module Types
  module Projects
    module Services
      class JiraServiceType < BaseObject
        graphql_name 'JiraService'

        implements(Types::Projects::ServiceType)

        authorize :admin_project
        # This is a placeholder for now for the actuall implementation of the JiraServiceType
        # Here we will want to expose a field with jira_projects fetched through Jira Rest API
        # MR implementing it https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28190
      end
    end
  end
end
