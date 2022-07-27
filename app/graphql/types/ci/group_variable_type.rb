# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class GroupVariableType < BaseObject
      graphql_name 'CiGroupVariable'
      description 'CI/CD variables for a group.'

      implements(VariableInterface)

      field :environment_scope, GraphQL::Types::String, null: true,
        description: 'Scope defining the environments that can use the variable.'
    end
  end
end
