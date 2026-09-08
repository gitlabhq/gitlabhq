# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class Engine
        # Class-level declaration DSL for aggregation engines: transients,
        # filters, dimensions, metrics, and the measurement macro.
        #
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- extended into engine
        # classes, so the ivars hold class-level DSL state, not mixin instance state
        module Dsl
          MEASUREMENT_AGGREGATES = {
            min: 'Minimum',
            max: 'Maximum',
            mean: 'Mean',
            quantile: 'Quantile of',
            sum: 'Sum of'
          }.freeze

          # `sum` is only meaningful for types that can be added up.
          SUMMABLE_MEASUREMENT_TYPES = %i[integer float].freeze

          def sql(...)
            Arel.sql(...)
          end

          def transient(name, &expression)
            return transients.fetch(name) unless expression

            transients[name] = expression
          end

          def transients
            @transients ||= {}
          end

          def filters(&block)
            @filters ||= []
            return @filters unless block

            @filters += DefinitionsCollector.new(filters_mapping, transients: transients).collect(&block)

            guard_definitions_uniqueness!(filters)

            @filters
          end

          def dimensions(&block)
            @dimensions ||= []

            return @dimensions unless block

            @dimensions += DefinitionsCollector.new(dimensions_mapping, transients: transients).collect(&block)

            guard_definitions_uniqueness!(dimensions + metrics)

            @dimensions
          end

          def metrics(&block)
            @metrics ||= []
            return @metrics unless block

            @metrics += DefinitionsCollector.new(metrics_mapping, transients: transients).collect(&block)

            guard_definitions_uniqueness!(dimensions + metrics)
            guard_dotted_identifiers!(@metrics)

            @metrics
          end

          # Declares a measurement (a row-level value with a base type) and
          # expands it into the standard aggregates as dotted metrics
          # (`<name>.min`, `<name>.max`, `<name>.mean`, `<name>.quantile`,
          # plus `<name>.sum` for summable types), exposed in GraphQL as one
          # nested group. The expression is also registered as a transient,
          # so other definitions can reuse it via `transient(name)`.
          def measurement(name, type, expression, description: nil, authorize: nil)
            aggregates = measurement_aggregates_for(type)
            guard_measurement_support!(aggregates.keys)

            expression = wrap_measurement_expression(expression)
            measurements[name] = { type: type, expression: expression, description: description }
            transients[name] ||= expression

            base_description = description || "`#{name}` measurement value"
            descriptions = aggregates.transform_values do |label|
              "#{label} #{base_description.downcase_first}"
            end

            summable = aggregates.key?(:sum)

            metrics do
              min :"#{name}.min", type, expression, description: descriptions[:min], authorize: authorize
              max :"#{name}.max", type, expression, description: descriptions[:max], authorize: authorize
              mean :"#{name}.mean", :float, expression, description: descriptions[:mean], authorize: authorize
              quantile :"#{name}.quantile", :float, expression, description: descriptions[:quantile],
                authorize: authorize, parameters: { quantile: { type: :float, in: 0.0..1.0 } }
              sum :"#{name}.sum", type, expression, description: descriptions[:sum], authorize: authorize if summable
            end
          end

          def measurements
            @measurements ||= {}
          end

          private

          def measurement_aggregates_for(type)
            return MEASUREMENT_AGGREGATES if SUMMABLE_MEASUREMENT_TYPES.include?(type)

            MEASUREMENT_AGGREGATES.except(:sum)
          end

          def guard_measurement_support!(required_aggregates)
            missing = required_aggregates - metrics_mapping.keys
            return if missing.empty?

            raise ArgumentError,
              "`measurement` is not supported by #{self}: " \
                "missing #{missing.inspect} in `metrics_mapping`"
          end

          # Metric expressions are called with an expression-params argument;
          # zero-arity lambdas would raise, so wrap them.
          def wrap_measurement_expression(expression)
            return expression unless expression.respond_to?(:arity) && expression.arity == 0

            ->(_params) { expression.call }
          end

          def guard_definitions_uniqueness!(parts)
            identifiers = parts.map(&:identifier)
            duplicates = identifiers.group_by(&:itself).select { |_k, v| v.size > 1 }.keys

            if duplicates.present?
              raise "Identical engine parts found: #{duplicates.inspect}. Engine parts identifiers must be unique."
            end

            guard_instance_keys_uniqueness!(parts)
          end

          def guard_instance_keys_uniqueness!(parts)
            keys = parts.map { |part| part.instance_key({}) }
            duplicates = keys.group_by(&:itself).select { |_k, v| v.size > 1 }.keys

            return unless duplicates.present?

            raise "Identical engine part keys found: #{duplicates.inspect}. " \
              "Engine parts identifiers must be unique after sanitization."
          end

          def guard_dotted_identifiers!(metrics)
            dotted, flat = metrics.partition { |metric| metric.identifier_parts.size == 2 }
            return if dotted.empty?

            prefixes = dotted.map { |metric| metric.identifier_parts.first }.uniq

            if prefixes.include?(:dimensions)
              raise "The `dimensions` prefix is reserved and cannot be used in dotted identifiers."
            end

            conflicts = prefixes & flat.map(&:identifier)
            return if conflicts.empty?

            raise "Dotted identifier prefixes conflict with flat identifiers: #{conflicts.inspect}."
          end
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
