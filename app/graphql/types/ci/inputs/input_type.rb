# frozen_string_literal: true

module Types
  module Ci
    module Inputs
      class InputType < BaseInputObject
        graphql_name 'CiInputsInputType'
        description 'Attributes for defining an input.'

        argument :id,
          ::Types::GlobalIDType[::Ci::PipelineScheduleInput],
          required: false,
          description: 'Global ID of the input. Only needed when updating an input.',
          experiment: { milestone: '17.11' }

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
