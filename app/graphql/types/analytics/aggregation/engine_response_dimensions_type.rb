# frozen_string_literal: true

module Types
  module Analytics
    module Aggregation
      module EngineResponseDimensionsType
        class << self
          def build(engine, graphql_context)
            adapter = ::Gitlab::Database::Aggregation::Graphql::Adapter
            types_prefix = adapter.types_prefix(graphql_context[:types_prefix])

            Class.new(BaseObject) do
              include BaseResponseType
              graphql_name "#{types_prefix}AggregationResponseDimensions"
              description "Response dimensions for #{types_prefix} aggregation engine"

              engine.dimensions.each { |dimension| declare_parameterized_field(dimension) }
            end
          end
        end
      end
    end
  end
end
