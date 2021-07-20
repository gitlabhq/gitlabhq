# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Authorization is in the resolver based on the parent project
  module Ci
    class JobTokenScopeType < BaseObject
      graphql_name 'CiJobTokenScopeType'

      field :projects, Types::ProjectType.connection_type, null: false,
        description: 'Allow list of projects that can be accessed by CI Job tokens created by this project.',
        method: :all_projects
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
