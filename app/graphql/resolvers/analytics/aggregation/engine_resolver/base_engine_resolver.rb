# frozen_string_literal: true

module Resolvers
  module Analytics
    module Aggregation
      module EngineResolver
        class BaseEngineResolver < BaseResolver # rubocop:disable Graphql/ResolverType -- type declared in subclasses
          class << self
            attr_accessor :engine
          end

          def resolve(**arguments)
            authorize!(object) if self.class.authorization.any?

            non_metric_filters = engine_class.filters.reject(&:metric?)
            filters = ::Gitlab::Database::Aggregation::Graphql::Adapter
              .arguments_to_filters(non_metric_filters, arguments)
            request = ::Gitlab::Database::Aggregation::Request.new(filters: filters, metrics: [])

            {
              engine: engine_class.new(context: { scope: aggregation_scope }),
              request: request,
              validate_request: method(:validate_request!)
            }
          end

          private

          def engine_class
            self.class.engine
          end

          def aggregation_scope
            raise NoMethodError # must be overloaded in dynamic class definition
          end

          def validate_request!(engine_request)
            # no-op; can be overloaded while mounting an engine to
            # further limit requests execution
          end
        end
      end
    end
  end
end
