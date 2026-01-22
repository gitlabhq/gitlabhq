# frozen_string_literal: true

module Types
  module Analytics
    module Aggregation
      module EngineResponseType
        class << self
          def build(engine, graphql_context)
            adapter = ::Gitlab::Database::Aggregation::Graphql::Adapter
            types_prefix = adapter.types_prefix(graphql_context[:types_prefix])

            Class.new(BaseObject) do
              include BaseResponseType
              graphql_name "#{types_prefix}AggregationResponse"
              description "Response for #{types_prefix} aggregation engine"

              field :dimensions,
                Types::Analytics::Aggregation::EngineResponseDimensionsType.build(engine, **graphql_context),
                resolver_method: :object,
                description: 'Aggregation dimensions. Every selected dimension will be used for aggregation.'

              engine.metrics.each { |metric| declare_parameterized_field(metric) }
            end
          end
        end
      end
    end
  end
end
