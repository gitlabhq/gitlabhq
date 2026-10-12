# frozen_string_literal: true

module Resolvers
  module Analytics
    module Aggregation
      module AggregationFieldResolver
        class << self
          def build(engine, response_type, **graphql_context)
            klass = Class.new(BaseAggregationFieldResolver)
            adapter = ::Gitlab::Database::Aggregation::Graphql::Adapter
            types_prefix = adapter.types_prefix(graphql_context[:types_prefix])
            klass.class_eval do
              graphql_name "#{types_prefix}AggregationFieldResolver"

              type response_type.connection_type, null: true

              max_page_size engine.max_page_size if engine.max_page_size

              adapter.each_filter_argument(engine.filters.select(&:metric?)) do |name, type, kwargs|
                argument(name, type, **kwargs) # rubocop:disable Graphql/Descriptions -- defined in adapter
              end
            end
            klass
          end
        end
      end
    end
  end
end
