# frozen_string_literal: true

module Resolvers
  module Analytics
    module Aggregation
      module AggregationFieldResolver
        class << self
          def build(response_type)
            klass = Class.new(BaseAggregationFieldResolver)
            klass.class_eval do
              type response_type.connection_type, null: true
            end
            klass
          end
        end
      end
    end
  end
end
