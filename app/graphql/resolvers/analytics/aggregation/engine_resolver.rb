# frozen_string_literal: true

module Resolvers
  module Analytics
    module Aggregation
      module EngineResolver
        class << self
          def build(engine, **graphql_context, &block)
            klass = Class.new(BaseEngineResolver)
            klass.engine = engine
            adapter = ::Gitlab::Database::Aggregation::Graphql::Adapter
            types_prefix = adapter.types_prefix(graphql_context[:types_prefix])
            klass.class_eval do
              # Anonymous resolvers need a name so graphql-ruby can build `Argument#path`.
              graphql_name "#{types_prefix}AggregationResolver"

              type Types::Analytics::Aggregation::AggregationScopeType.build(engine, **graphql_context),
                null: true

              adapter.each_filter_argument(engine.filters.reject(&:metric?)) do |name, type, kwargs|
                argument(name, type, **kwargs) # rubocop:disable Graphql/Descriptions -- defined in adapter
              end
            end
            klass.class_eval(&block) if block

            klass
          end
        end
      end
    end
  end
end
