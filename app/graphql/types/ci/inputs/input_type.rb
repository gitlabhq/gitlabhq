# frozen_string_literal: true

# This class represents a GraphQL `Input` object that allows users to set CI inputs values when running a pipeline or
# configuring a pipeline schedule. The `Inputs` namespace refers to CI inputs, and the `InputType` class name refers to
# a GraphQL `Input` object.

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
          Inputs::ValueType,
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
