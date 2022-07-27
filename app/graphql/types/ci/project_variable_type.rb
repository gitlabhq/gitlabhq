# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class ProjectVariableType < BaseObject
      graphql_name 'CiProjectVariable'
      description 'CI/CD variables for a project.'

      implements(VariableInterface)

      field :environment_scope, GraphQL::Types::String, null: true,
        description: 'Scope defining the environments that can use the variable.'
    end
  end
end
