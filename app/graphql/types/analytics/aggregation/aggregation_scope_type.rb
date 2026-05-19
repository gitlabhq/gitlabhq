# frozen_string_literal: true

module Types
  module Analytics
    module Aggregation
      module AggregationScopeType
        class << self
          def build(engine, **graphql_context)
            adapter = ::Gitlab::Database::Aggregation::Graphql::Adapter
            types_prefix = adapter.types_prefix(graphql_context[:types_prefix])
            response_type = EngineResponseType.build(engine, **graphql_context)
            inner_resolver = Resolvers::Analytics::Aggregation::AggregationFieldResolver.build(engine, response_type)

            Class.new(BaseObject) do
              graphql_name "#{types_prefix}AggregationScope"
              description "Aggregation scope for `#{types_prefix}`. " \
                "Apply ordering and pagination on the aggregation."

              field :aggregated,
                resolver: inner_resolver,
                description: 'Aggregated data.'
            end
          end
        end
      end
    end
  end
end
