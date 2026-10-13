# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class Ratio < MetricDefinition
          AGGREGATE_FUNCTIONS = %i[sum count uniqExact avg].freeze
          DEFAULT_AGGREGATE = :sum
          # A ratio is fractional by nature. An integer type would be coerced to a
          # GraphQL Int, which truncates every value to 0 without raising.
          SUPPORTED_TYPE = :float

          attr_reader :numerator_agg, :denominator_agg

          # Aggregates the numerator and denominator separately, then divides. This is a
          # ratio of sums, not the mean of per-row ratios that `mean` would produce.
          #
          # The numerator takes the primary expression slot and the denominator the
          # secondary one, leaving no slot for `if:`.
          def initialize(
            name, type = :float, numerator:, denominator:,
            numerator_agg: DEFAULT_AGGREGATE, denominator_agg: DEFAULT_AGGREGATE, **kwargs)
            validate_no_condition!(kwargs)
            validate_type!(name, type)

            @numerator_agg = validate_aggregate!(numerator_agg)
            @denominator_agg = validate_aggregate!(denominator_agg)

            super(name, type, numerator, if: denominator, **kwargs)
          end

          def identifier
            dotted_name? ? name : :"#{name}_ratio"
          end

          def to_outer_arel(context)
            inner_query = Arel::Table.new(context[:inner_query_name])

            numerator = aggregate(numerator_agg, inner_column!(inner_query, context, :local_alias, :numerator))
            denominator = aggregate(denominator_agg,
              inner_column!(inner_query, context, :local_secondary_alias, :denominator))

            # ClickHouse returns inf/nan for division by zero rather than raising, so
            # guard the denominator to return NULL ("no data") instead.
            numerator / Arel::Nodes::NamedFunction.new('nullIf', [denominator, Arel::Nodes.build_quoted(0)])
          end

          # Both sides are required. Catching a nil expression here, at plan
          # validation, returns a proper error response instead of raising during
          # query construction, where it would surface as a 500.
          def validate_part(part)
            super

            # An expression may trust the parameter allowlist, so stop before
            # calling one with values `super` has already rejected.
            return if part.errors.any?

            missing_sides(part).each do |side|
              part.errors.add(
                :base,
                format(
                  s_("AggregationEngine|metric '%{metric}' has no %{side} for the given parameters"),
                  metric: identifier,
                  side: side
                )
              )
            end
          end

          private

          def missing_sides(part)
            params = expression_params(name => part.configuration)

            { numerator: expression, denominator: secondary_expression }.filter_map do |side, expr|
              side unless expr&.call(params)
            end
          end

          # Defence in depth for callers that build a query without validating the
          # plan first, such as specs invoking the engine internals directly.
          # `validate_part` is what a request actually goes through.
          def inner_column!(inner_query, context, alias_key, side)
            alias_name = context[alias_key]

            unless alias_name
              raise ArgumentError,
                "`ratio` metric `#{name}` built no #{side} projection: its expression returned nil. " \
                  "Both `numerator` and `denominator` must return an expression for every parameter combination."
            end

            inner_query[alias_name]
          end

          def aggregate(function, column)
            Arel::Nodes::NamedFunction.new(function.to_s, [column])
          end

          def validate_no_condition!(kwargs)
            return unless kwargs.key?(:if)

            raise ArgumentError,
              '`if:` is not supported by `ratio`; encode the condition in the ' \
                'numerator/denominator expressions instead'
          end

          # Runs before `super`, so the name is passed in rather than read off the
          # attr_reader, which is not populated yet.
          def validate_type!(name, type)
            return if symbolize(type) == SUPPORTED_TYPE

            raise ArgumentError,
              "`ratio` metric `#{name}` must be declared as `#{SUPPORTED_TYPE.inspect}`, got #{type.inspect}. " \
                "A ratio is fractional and other types silently lose precision."
          end

          def validate_aggregate!(function)
            symbolized = symbolize(function)
            return symbolized if AGGREGATE_FUNCTIONS.include?(symbolized)

            raise ArgumentError,
              "Unsupported aggregate function #{function.inspect} for `ratio`. " \
                "Supported functions: #{AGGREGATE_FUNCTIONS.join(', ')}"
          end

          # Options come straight from the DSL, so they may be anything a caller
          # mistyped. Values that cannot be symbolized fall through to the
          # allowlist check and get the same clear ArgumentError as a bad symbol.
          def symbolize(value)
            value.to_sym if value.respond_to?(:to_sym)
          end
        end
      end
    end
  end
end
