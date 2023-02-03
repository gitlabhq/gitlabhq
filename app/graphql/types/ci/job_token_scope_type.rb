# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Authorization is in the resolver based on the parent project
  module Ci
    class JobTokenScopeType < BaseObject
      graphql_name 'CiJobTokenScopeType'

      field :projects,
            Types::ProjectType.connection_type,
            null: false,
            description: 'Allow list of projects that can be accessed by CI Job tokens created by this project.',
            method: :outbound_projects,
            deprecated: {
              reason: 'The `projects` attribute is being deprecated. Use `outbound_allowlist`',
              milestone: '15.9'
            }

      field :outbound_allowlist,
            Types::ProjectType.connection_type,
            null: false,
            description: "Allow list of projects that are accessible using the current project's CI Job tokens.",
            method: :outbound_projects

      field :inbound_allowlist,
            Types::ProjectType.connection_type,
            null: false,
            description: "Allow list of projects that can access the current project through its CI Job tokens.",
            method: :inbound_projects
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
