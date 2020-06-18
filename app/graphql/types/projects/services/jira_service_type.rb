# frozen_string_literal: true

module Types
  module Projects
    module Services
      class JiraServiceType < BaseObject
        graphql_name 'JiraService'

        implements(Types::Projects::ServiceType)

        authorize :admin_project

        field :projects,
              Types::Projects::Services::JiraProjectType.connection_type,
              null: true,
              connection: false,
              extensions: [Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension],
              description: 'List of Jira projects fetched through Jira REST API',
              resolver: Resolvers::Projects::JiraProjectsResolver
      end
    end
  end
end
