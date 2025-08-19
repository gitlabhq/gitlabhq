# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class ProjectStatisticsRedirectType < BaseObject
    graphql_name 'ProjectStatisticsRedirect'

    def self.authorization_scopes
      super + [:ai_workflows]
    end

    field :repository, GraphQL::Types::String, null: false,
      description: 'Redirection Route for repository.',
      scopes: [:api, :read_api, :ai_workflows]

    field :wiki, GraphQL::Types::String, null: false,
      description: 'Redirection Route for wiki.'

    field :build_artifacts, GraphQL::Types::String, null: false,
      description: 'Redirection Route for job_artifacts.'

    field :packages, GraphQL::Types::String, null: false,
      description: 'Redirection Route for packages.'

    field :snippets, GraphQL::Types::String, null: false,
      description: 'Redirection Route for snippets.'

    field :container_registry, GraphQL::Types::String, null: false,
      description: 'Redirection Route for container_registry.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
