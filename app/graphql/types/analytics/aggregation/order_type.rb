# frozen_string_literal: true

module Types
  module Analytics
    module Aggregation
      class OrderType < BaseInputObject
        graphql_name 'AggregationOrder'

        argument :direction, SortDirectionEnum, required: true, description: 'Sorting direction.'
        argument :identifier, String, required: true, description: 'Dimension or metric identifier.'
        argument :parameters, GraphQL::Types::JSON, required: false, # rubocop:disable Graphql/JSONType -- Accepts dimension-specific parameters as untyped JSON; validation occurs at query execution time
          description: 'Parameters for parameterized dimensions.'
      end
    end
  end
end
