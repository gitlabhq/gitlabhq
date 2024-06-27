# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        module Components
          class InputTypeEnum < BaseEnum
            graphql_name 'CiCatalogResourceComponentInputType'
            description 'Available input types'

            ::Gitlab::Ci::Config::Interpolation::Inputs.input_types.each do |input_type|
              value input_type.upcase, description: "#{input_type.capitalize} input", value: input_type
            end
          end
        end
      end
    end
  end
end
