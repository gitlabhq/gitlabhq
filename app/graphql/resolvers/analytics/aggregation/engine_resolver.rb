# frozen_string_literal: true

module Resolvers
  module Analytics
    module Aggregation
      module EngineResolver
        class << self
          # Factory method that dynamically creates a GraphQL resolver class for a specific aggregation engine
          # This method constructs a resolver subclass that wraps a given
          # aggregation engine (e.g., ClickHouse or ActiveRecord)
          # @param engine [Gitlab::Database::Aggregation::Engine] The aggregation engine instance.
          def build(engine, **graphql_context, &block)
            klass = Class.new(BaseEngineResolver)
            klass.engine = engine
            adapter = ::Gitlab::Database::Aggregation::Graphql::Adapter
            klass.class_eval do
              type Types::Analytics::Aggregation::EngineResponseType.build(engine, **graphql_context).connection_type,
                null: true

              adapter.each_filter_argument(engine.filters) do |name, type, kwargs|
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
