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
            klass.class_eval do
              type Types::Analytics::Aggregation::AggregationScopeType.build(engine, **graphql_context),
                null: true

              adapter.each_filter_argument(engine.filters.reject(&:metric?)) do |name, type, kwargs|
                argument(name, type, **kwargs) # rubocop:disable Graphql/Descriptions -- defined in adapter
              end
            end
            klass.class_eval(&block)

            klass
          end
        end
      end
    end
  end
end
