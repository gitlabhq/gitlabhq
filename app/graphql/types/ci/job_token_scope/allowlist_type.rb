# frozen_string_literal: true

module Types
  module Ci
    module JobTokenScope
      # rubocop: disable Graphql/AuthorizeTypes -- Authorization is handled by parent class
      class AllowlistType < BaseObject
        graphql_name 'CiJobTokenScopeAllowlist'

        field :groups_allowlist,
          Types::Ci::JobTokenScope::AllowlistEntryType.connection_type,
          null: true,
          description: "Allowlist of groups that can access the current project " \
            "by authenticating with a CI/CD job token."

        field :projects_allowlist,
          Types::Ci::JobTokenScope::AllowlistEntryType.connection_type,
          null: true,
          description: "Allowlist of projects that can access the current project " \
            "by authenticating with a CI/CD job token."
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
