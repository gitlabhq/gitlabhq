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
            metrics = build_metric_parts(metric_selections, engine)

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

          # Metric group selections (built from dotted identifiers like
          # `duration.max`) are expanded into one part per sub-field.
          def build_metric_parts(selections, engine)
            group_prefixes = metric_group_prefixes(engine)

            part_selections(selections).flat_map do |field|
              next [{ identifier: field.name.to_sym, parameters: field.arguments || {} }] unless
                group_prefixes.include?(field.name)

              part_selections(field.selections).map do |sub_field|
                { identifier: :"#{field.name}.#{sub_field.name}", parameters: sub_field.arguments || {} }
              end
            end
          end

          def metric_group_prefixes(engine)
            engine.class.metrics.filter_map do |metric|
              parts = metric.identifier_parts
              parts.first if parts.size == 2
            end.to_set
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
