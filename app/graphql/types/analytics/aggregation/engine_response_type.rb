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
              description "Response for `#{types_prefix}` aggregation engine"
              connection_type_class Types::Analytics::Aggregation::EngineResponseConnectionType

              authorize_granular_token skip_reason: :parent_authorizes if graphql_context[:granular_authorization_opts]

              field :dimensions,
                Types::Analytics::Aggregation::EngineResponseDimensionsType.build(engine, **graphql_context),
                resolver_method: :object,
                description: 'Aggregation dimensions. Every selected dimension will be used for aggregation.'

              grouped_metrics, flat_metrics = engine.metrics.partition { |m| m.identifier_parts.size == 2 }

              flat_metrics.each { |metric| declare_parameterized_field(metric) }

              grouped_metrics.group_by { |m| m.identifier_parts.first }.each do |group_name, metrics|
                field group_name,
                  Types::Analytics::Aggregation::EngineResponseMetricGroupType.build(group_name, metrics,
                    graphql_context),
                  resolver_method: :object,
                  description: "Aggregated `#{group_name}` metrics."
              end
            end
          end
        end
      end
    end
  end
end
