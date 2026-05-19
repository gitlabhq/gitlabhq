# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        # Filters by an aggregated metric value. Applied as a HAVING clause on
        # the outer (post-aggregation) query. The referenced metric must be
        # part of the same request.
        class MetricFilterDefinition < FilterDefinition
          def metric?
            true
          end

          def apply_inner(query_builder, _filter_config)
            query_builder
          end

          def apply_outer(_query_builder, _filter_config, _metric_column)
            raise NoMethodError
          end

          def validate_definition!(engine_class)
            metric_identifiers = engine_class.metrics.map(&:identifier)
            return if identifier.in?(metric_identifiers)

            raise ArgumentError,
              "MetricFilter '#{identifier}' references metric '#{identifier}' " \
                "which is not defined in the engine. Available metrics: #{metric_identifiers.inspect}"
          end

          def validate_part(part)
            super
            validate_metric_requested(part)
          end

          private

          def validate_metric_requested(part)
            return if part.query_plan.metrics.any? { |m| m.matches?(part.configuration) }

            part.errors.add(:base,
              format(s_("AggregationEngine|metric `%{identifier}` must be requested to filter by it"),
                identifier: identifier))
          end
        end
      end
    end
  end
end
