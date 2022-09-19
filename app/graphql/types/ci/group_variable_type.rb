# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class GroupVariableType < BaseObject
      graphql_name 'CiGroupVariable'
      description 'CI/CD variables for a group.'

      connection_type_class(Types::Ci::GroupVariableConnectionType)
      implements(VariableInterface)

      field :environment_scope, GraphQL::Types::String,
            null: true,
            description: 'Scope defining the environments that can use the variable.'

      field :masked, GraphQL::Types::Boolean,
            null: true,
            description: 'Indicates whether the variable is masked.'

      field :protected, GraphQL::Types::Boolean,
            null: true,
            description: 'Indicates whether the variable is protected.'
    end
  end
end
