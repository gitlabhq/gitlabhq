# frozen_string_literal: true

module Resolvers
  module Analytics
    module Aggregation
      module AggregationFieldResolver
        class << self
          def build(engine, response_type)
            klass = Class.new(BaseAggregationFieldResolver)
            adapter = ::Gitlab::Database::Aggregation::Graphql::Adapter
            klass.class_eval do
              type response_type.connection_type, null: true

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
