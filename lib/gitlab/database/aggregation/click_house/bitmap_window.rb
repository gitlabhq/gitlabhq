# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class BitmapWindow < MetricDefinition
          attr_reader :over_dimension, :operation, :lag_offset

          VALID_OPERATIONS = %i[lag intersection].freeze

          def initialize(name, type = :integer, expression = nil, operation:, over:, lag_offset: 1, **kwargs)
            raise ArgumentError, "Invalid operation: #{operation}" unless VALID_OPERATIONS.include?(operation)

            @over_dimension = over
            @operation = operation
            @lag_offset = lag_offset
            super(name, type, expression, **kwargs)
          end

          # Definition-time validation: called by the engine after all metrics and dimensions
          # are registered, so we can assert the over_dimension exists in the engine.
          def validate_definition!(engine_class)
            dimension_names = engine_class.dimensions.map(&:name)
            return if over_dimension.in?(dimension_names)

            raise ArgumentError,
              "BitmapWindow metric '#{name}' references dimension '#{over_dimension}' " \
                "which is not defined in the engine. Available dimensions: #{dimension_names.inspect}"
          end

          def validate_part(part)
            return if part.query_plan.dimensions.any? { |d| d.definition.name == over_dimension }

            part.errors.add(
              :base,
              format(
                s_("AggregationEngine|metric '%{metric}' requires dimension '%{dimension}' to be requested"),
                metric: identifier,
                dimension: over_dimension
              )
            )
          end

          def identifier
            :"#{name}_count"
          end

          def to_inner_arel(_context)
            bitmap_expression = expression ? expression.call : Arel.sql(name.to_s)
            Arel::Nodes::SqlLiteral.new("groupBitmapState(#{bitmap_expression})")
          end

          def to_outer_arel(context)
            inner_query_name = context[:inner_query_name]
            local_alias = context.fetch(:local_alias, name)
            col_ref = "`#{inner_query_name}`.`#{local_alias}`"
            Arel::Nodes::SqlLiteral.new("groupBitmapMergeState(#{col_ref})")
          end

          def requires_window?
            true
          end

          def build_window_sql(_context, bitmap_alias, over_alias: over_dimension)
            case operation
            when :lag
              build_lag_sql(bitmap_alias, over_alias)
            when :intersection
              build_intersection_sql(bitmap_alias, over_alias)
            end
          end

          def finalization_sql(alias_name)
            case operation
            when :lag
              "bitmapCardinality(finalizeAggregation(#{alias_name}))"
            when :intersection
              "finalizeAggregation(#{alias_name})"
            end
          end

          private

          def build_lag_sql(bitmap_alias, over_alias)
            # LaggedCount#to_outer_arel returns a UInt64 (from uniqExact), not a bitmap array,
            # so 0 is the correct default for the first row - unlike build_intersection_sql
            # which uses [] because RetainedCount#to_outer_arel returns Array(UInt64).
            "lagInFrame(#{bitmap_alias}, #{lag_offset}, 0) OVER (ORDER BY #{over_alias} ASC)".squish
          end

          def build_intersection_sql(bitmap_alias, over_alias)
            # Only reached when operation == :intersection (i.e. RetainedCount subclass).
            # RetainedCount#to_outer_arel returns Array(UInt64) via groupArray, so
            # lagInFrame works on arrays and [] is the correct default for the first row.
            lagged = "lagInFrame(#{bitmap_alias}, #{lag_offset}, []) OVER (ORDER BY #{over_alias} ASC)"
            "length(arrayIntersect(#{bitmap_alias}, #{lagged}))".squish
          end
        end
      end
    end
  end
end
