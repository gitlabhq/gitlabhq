# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class QueryPlan
        # Resolves part-level authorization (see `Aggregation::Authorization`)
        # while planning. Unauthorized metrics are pruned from the plan (their
        # fields render as `null`); `QueryPlan` fails validation only when the
        # remaining plan cannot run.
        #
        # Expects the including plan to define `requested_metrics`: every
        # metric part of the request, before pruning.
        module Authorization
          extend ActiveSupport::Concern
          include Gitlab::Utils::StrongMemoize

          def unauthorized_metrics
            return [] unless authorization_required?

            requested_metrics.reject { |metric| authorized_part?(metric) }
          end
          strong_memoize_attr :unauthorized_metrics

          # Every unauthorized part of the request, including pruned metrics.
          def unauthorized_parts
            return [] unless authorization_required?

            unauthorized_metrics + unauthorized_dimensions + unauthorized_filters + unauthorized_order
          end
          strong_memoize_attr :unauthorized_parts

          private

          def unauthorized_dimensions
            dimensions.reject { |dimension| authorized_part?(dimension) }
          end

          def unauthorized_filters
            filters.reject do |filter|
              authorized_part?(filter) && engine.authorized_definition?(referenced_metric_definition(filter))
            end
          end

          def unauthorized_order
            order.reject { |order_part| engine.authorized_definition?(order_definition(order_part)) }
          end

          def unauthorized_message(part)
            case part
            when Metric
              format(s_("AggregationEngine|access to metric '%{identifier}' is not authorized"),
                identifier: part.configuration[:identifier])
            when Dimension
              format(s_("AggregationEngine|access to dimension '%{identifier}' is not authorized"),
                identifier: part.definition.identifier)
            when Filter
              format(s_("AggregationEngine|access to filter '%{identifier}' is not authorized"),
                identifier: part.definition.identifier)
            else # Order, the only other plan part
              format(s_("AggregationEngine|ordering by '%{identifier}' is not authorized"),
                identifier: order_definition(part).identifier)
            end
          end

          def authorization_required?
            engine.authorization_required?
          end
          strong_memoize_attr :authorization_required?

          # Metric filters must also be authorized for the metric they reference.
          def referenced_metric_definition(filter)
            return unless filter.definition.try(:metric?)

            engine.class.metrics.find { |metric| metric.identifier == filter.definition.identifier }
          end

          # A sort order referencing a pruned metric has no plan part; resolve
          # the definition directly to report it as unauthorized rather than as
          # an unknown identifier.
          def order_definition(order_part)
            order_part.definition ||
              engine.class.metrics.find { |metric| metric.identifier == order_part.configuration[:identifier] }
          end

          # Parts with an unresolved definition are reported by plan validation.
          def authorized_part?(part)
            part.definition.nil? || engine.authorized_definition?(part.definition)
          end
        end
      end
    end
  end
end
