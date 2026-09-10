# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        # Buckets a numeric expression into ordinal tiers (`tier_0` .. `tier_N`)
        # by client-provided ascending integer `thresholds`. A value below the
        # first threshold lands in `tier_0`; a value at or above the last
        # threshold lands in the highest tier, so N thresholds produce N+1 tiers.
        class TierDimension < DimensionDefinition
          include ParameterizedDefinition

          # Keeps tier labels single-digit (`tier_0` .. `tier_9`), so their
          # lexicographic order matches the numeric tier order in `ORDER BY`.
          MAX_THRESHOLDS = 9

          THRESHOLDS_PARAMETER = {
            thresholds: {
              type: :integer,
              array: true,
              description: 'Ascending tier boundaries. Values below the first threshold map to `tier_0`, ' \
                'values at or above the last threshold map to the highest tier.'
            }
          }.freeze

          def initialize(*args, parameters: nil, **kwargs)
            super(*args, parameters: THRESHOLDS_PARAMETER.merge(parameters || {}), **kwargs)
          end

          def to_outer_arel(context)
            bucketed_column = super
            thresholds = instance_parameter(:thresholds, context[name])

            # `Integer()` re-coercion keeps the interpolation injection-safe even
            # when a caller bypasses plan validation.
            arguments = thresholds.flat_map.with_index do |threshold, index|
              [bucketed_column.lt(Integer(threshold)), Arel::Nodes.build_quoted(tier_label(index))]
            end
            arguments << Arel::Nodes.build_quoted(tier_label(thresholds.size))

            context[:scope].func('multiIf', arguments)
          end

          def validate_part(part)
            super

            thresholds = instance_parameter(:thresholds, part.configuration)

            if thresholds.blank?
              return part.errors.add(:thresholds,
                s_("AggregationEngine|parameter `thresholds` is required"))
            end

            if thresholds.size > MAX_THRESHOLDS
              return part.errors.add(:thresholds,
                format(s_("AggregationEngine|parameter `thresholds` supports at most %{max} values"),
                  max: MAX_THRESHOLDS))
            end

            return if valid_thresholds?(thresholds)

            part.errors.add(:thresholds,
              s_("AggregationEngine|parameter `thresholds` must be strictly ascending positive integers"))
          end

          private

          def tier_label(index)
            "tier_#{index}"
          end

          def valid_thresholds?(thresholds)
            thresholds.all? { |threshold| threshold.is_a?(Integer) && threshold >= 1 } &&
              thresholds.each_cons(2).all? { |previous, current| previous < current }
          end
        end
      end
    end
  end
end
