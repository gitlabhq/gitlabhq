# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class VariableType < BaseObject
      graphql_name 'CiVariable'

      field :id, GraphQL::Types::ID, null: false,
        description: 'ID of the variable.'

      field :key, GraphQL::Types::String, null: true,
        description: 'Name of the variable.'

      field :value, GraphQL::Types::String, null: true,
        description: 'Value of the variable.'

      field :variable_type, ::Types::Ci::VariableTypeEnum, null: true,
        description: 'Type of the variable.'

      field :protected, GraphQL::Types::Boolean, null: true,
        description: 'Indicates whether the variable is protected.'

      field :masked, GraphQL::Types::Boolean, null: true,
        description: 'Indicates whether the variable is masked.'

      field :raw, GraphQL::Types::Boolean, null: true,
        description: 'Indicates whether the variable is raw.'

      field :environment_scope, GraphQL::Types::String, null: true,
        description: 'Scope defining the environments in which the variable can be used.'

      def environment_scope
        if object.respond_to?(:environment_scope)
          object.environment_scope
        end
      end
    end
  end
end
