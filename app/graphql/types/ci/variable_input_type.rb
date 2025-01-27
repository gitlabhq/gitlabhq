# frozen_string_literal: true

module Types
  module Ci
    class VariableInputType < BaseInputObject
      graphql_name 'CiVariableInput'
      description 'Attributes for defining a CI/CD variable.'

      argument :key, GraphQL::Types::String, description: 'Name of the variable.'
      argument :value, GraphQL::Types::String, description: 'Value of the variable.'
      argument :variable_type, Types::Ci::VariableTypeEnum, description: 'Type of variable.', required: false
    end
  end
end
