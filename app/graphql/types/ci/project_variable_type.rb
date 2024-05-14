# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class ProjectVariableType < BaseObject
      graphql_name 'CiProjectVariable'
      description 'CI/CD variables for a project.'

      connection_type_class Types::Ci::ProjectVariableConnectionType
      implements VariableInterface

      field :environment_scope, GraphQL::Types::String,
        null: true,
        description: 'Scope defining the environments that can use the variable.'

      field :protected, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is protected.'

      field :hidden, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is hidden.'

      field :masked, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is masked.'

      field :description, GraphQL::Types::String,
        null: true,
        description: 'Description of the variable.'

      def value
        ::Ci::VariableValue.new(object).evaluate
      end
    end
  end
end
