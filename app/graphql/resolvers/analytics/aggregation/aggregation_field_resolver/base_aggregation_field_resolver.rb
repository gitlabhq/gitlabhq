# frozen_string_literal: true

module Resolvers
  module Analytics
    module Aggregation
      module AggregationFieldResolver
        class BaseAggregationFieldResolver < BaseResolver # rubocop:disable Graphql/ResolverType -- type declared in subclasses
          include LooksAhead

          argument :order_by,
            [Types::Analytics::Aggregation::OrderType],
            required: false,
            description: 'Sorting order list for the aggregated data.'

          def resolve_with_lookahead(**arguments)
            scope_context = object
            request = build_aggregation_request(scope_context, arguments)
            scope_context[:validate_request].call(request)

            response = scope_context[:engine].execute(request)

            raise GraphQL::ExecutionError, response.errors.join(' ') unless response.success?

            response.payload[:data]
          end

          private

          def build_aggregation_request(scope_context, arguments)
            outer_request = scope_context[:request]
            engine = scope_context[:engine]

            nodes_selection = lookahead.selections.detect { |s| s.name == :nodes }
            selections = nodes_selection&.selections || []

            order = build_order(arguments.delete(:order_by))

            metric_filters = ::Gitlab::Database::Aggregation::Graphql::Adapter
              .arguments_to_filters(engine.class.filters.select(&:metric?), arguments)

            dimensions_selection = selections.detect { |s| s.name == :dimensions }
            dimensions = dimensions_selection ? build_parts_from_selection(dimensions_selection.selections) : []

            metric_selections = selections.reject { |s| s.name == :dimensions }
            metrics = build_parts_from_selection(metric_selections)

            ::Gitlab::Database::Aggregation::Request.new(
              filters: outer_request.filters + metric_filters,
              dimensions: dimensions,
              metrics: metrics,
              order: order
            )
          end

          def build_parts_from_selection(selections)
            part_selections(selections).map do |field|
              { identifier: field.name.to_sym, parameters: field.arguments || {} }
            end
          end

          def part_selections(selections)
            selections.reject { |s| s.name.to_s.start_with?('__') }
          end

          def build_order(order_by)
            return unless order_by

            order_by.map do |order_input|
              order = order_input.to_hash
              order[:identifier] = order[:identifier].underscore.to_sym
              order[:parameters] = (order[:parameters] || {}).symbolize_keys
              order
            end
          end
        end
      end
    end
  end
end
