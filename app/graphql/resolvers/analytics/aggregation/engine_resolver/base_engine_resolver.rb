# frozen_string_literal: true

module Resolvers
  module Analytics
    module Aggregation
      module EngineResolver
        class BaseEngineResolver < BaseResolver # rubocop:disable Graphql/ResolverType -- type declared in subclasses
          class << self
            attr_accessor :engine
          end

          include LooksAhead

          argument :order_by,
            [Types::Analytics::Aggregation::OrderType],
            required: false,
            description: 'Sorting order list for the aggregated data.'

          def resolve_with_lookahead(**arguments)
            request = build_aggregation_request(arguments)
            validate_request!(request)

            response = engine.execute(request)

            raise GraphQL::ExecutionError, response.errors.join(' ') unless response.success?

            response.payload[:data]
          end

          private

          def engine
            engine_class.new(context: { scope: aggregation_scope })
          end

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

          def build_aggregation_request(arguments)
            selections = lookahead.selections.first.selections

            # prepare order
            order = build_order(arguments.delete(:order_by))

            # prepare filters: arguments - orderBy = filters
            filters = ::Gitlab::Database::Aggregation::Graphql::Adapter.arguments_to_filters(engine_class, arguments)

            # prepare dimensions
            dimensions_selection = selections.detect { |s| s.name == :dimensions }
            dimensions = dimensions_selection ? build_parts_from_selection(dimensions_selection.selections) : []

            # prepare metrics: selections - dimensions = metrics
            metric_selections = selections.reject { |s| s.name == :dimensions }
            metrics = build_parts_from_selection(metric_selections)

            ::Gitlab::Database::Aggregation::Request.new(
              filters: filters, dimensions: dimensions, metrics: metrics, order: order
            )
          end

          def build_parts_from_selection(selections)
            selections.map do |field|
              { identifier: field.name.to_sym, parameters: field.arguments || {} }
            end
          end

          def build_order(order_by)
            return unless order_by

            order_by.map do |order_input|
              order = order_input.to_hash
              order[:identifier] = order[:identifier].to_sym
              order[:parameters] ||= {}
              order
            end
          end
        end
      end
    end
  end
end
