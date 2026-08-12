# frozen_string_literal: true

module Types
  module Analytics
    module Aggregation
      module EngineResponseMetricGroupType
        class << self
          # Builds a sub-object type for metrics sharing a dotted identifier
          # prefix (`duration.max`, `duration.mean` => `duration { max mean }`).
          def build(group_name, metrics, graphql_context)
            adapter = ::Gitlab::Database::Aggregation::Graphql::Adapter
            types_prefix = adapter.types_prefix(graphql_context[:types_prefix])

            Class.new(BaseObject) do
              include BaseResponseType
              graphql_name "#{types_prefix}AggregationResponse#{group_name.to_s.camelize}Metrics"
              description "Aggregated `#{group_name}` metrics for `#{types_prefix}` aggregation engine"

              authorize_granular_token skip_reason: :parent_authorizes if graphql_context[:granular_authorization_opts]

              metrics.each do |metric|
                declare_parameterized_field(metric, field_name: metric.identifier_parts.last)
              end
            end
          end
        end
      end
    end
  end
end
