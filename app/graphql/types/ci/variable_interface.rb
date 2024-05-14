# frozen_string_literal: true

module Types
  module Ci
    module VariableInterface
      include Types::BaseInterface

      graphql_name 'CiVariable'

      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID of the variable.'

      field :key, GraphQL::Types::String,
        null: true,
        description: 'Name of the variable.'

      field :raw, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is raw.'

      field :value, GraphQL::Types::String,
        null: true,
        description: 'Value of the variable.'

      field :variable_type, ::Types::Ci::VariableTypeEnum,
        null: true,
        description: 'Type of the variable.'
    end
  end
end
