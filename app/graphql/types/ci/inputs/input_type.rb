# frozen_string_literal: true

module Types
  module Ci
    module Inputs
      class InputType < BaseInputObject
        graphql_name 'CiInputsInputType'
        description 'Attributes for defining an input.'

        argument :key,
          GraphQL::Types::String,
          required: true,
          description: 'Name of the input.'

        argument :value,
          Inputs::ValueInputType,
          required: true,
          description: 'Value of the input.'
      end
    end
  end
end
