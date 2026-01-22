# frozen_string_literal: true

module Types
  module Analytics
    module Aggregation
      class OrderType < BaseInputObject
        graphql_name 'AggregationOrder'

        argument :direction, SortDirectionEnum, required: true, description: 'Sorting direction.'
        argument :identifier, String, required: true, description: 'Dimension or metric identifier.'
      end
    end
  end
end
