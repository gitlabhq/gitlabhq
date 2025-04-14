# frozen_string_literal: true

module Types
  module Ci
    module Inputs
      class TypeEnum < BaseEnum
        graphql_name 'CiInputsType'
        description 'Available input types'

        ::Ci::PipelineCreation::Inputs::SpecInputs.input_types.each do |input_type|
          value input_type.upcase, description: "#{input_type.capitalize} input", value: input_type
        end
      end
    end
  end
end
