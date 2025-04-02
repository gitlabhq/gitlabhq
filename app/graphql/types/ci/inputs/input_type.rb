# frozen_string_literal: true

module Types
  module Ci
    module Inputs
      class InputType < BaseInputObject
        graphql_name 'CiInputsInput'
        description 'Attributes for defining an input.'

        argument :name,
          GraphQL::Types::String,
          required: true,
          description: 'Name of the input.'

        argument :value,
          Inputs::ValueInputType,
          required: true,
          description: 'Value of the input.'

        argument :destroy,
          GraphQL::Types::Boolean,
          required: false,
          description: 'Set to `true` to delete the input.'
      end
    end
  end
end
