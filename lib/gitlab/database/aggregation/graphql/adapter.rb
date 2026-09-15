# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module Graphql
        module Adapter
          class << self
            def types_prefix(name)
              name.to_s.downcase.camelize
            end

            def each_filter_argument(filters)
              filters.each do |filter|
                filter_to_arguments(filter).each { |args| yield(*args) }
              end
            end

            def arguments_to_filters(filters, arguments)
              filters
                .map { |filter| build_filter(filter, arguments) }
                .reject { |f| f[:values].blank? }
            end

            # `orderBy.parameters` arrives as untyped JSON while dimension/metric
            # field arguments are coerced by typed GraphQL scalars. Order entries
            # are matched to parts by value-sensitive instance keys, so order
            # parameters must be coerced with the same scalars to line up
            # (for example a `Time` origin vs its ISO 8601 string).
            def coerce_order_parameters!(request, engine)
              return if request.order.none? { |config| config[:parameters].present? }

              orderable_parts = request.to_query_plan(engine).orderable_parts

              request.order.each do |config|
                next if config[:parameters].blank?

                # Unknown identifiers and non-parameterized definitions pass
                # through untouched; QueryPlan validation reports them.
                definition = orderable_parts
                  .detect { |part| part.configuration[:identifier] == config[:identifier] }&.definition
                next unless definition.respond_to?(:parameters)

                config[:parameters] = coerce_parameters(definition, config)
              end
            end

            def graphql_type(type)
              case type.to_sym
              when :integer then ::GraphQL::Types::Int
              when :boolean then ::GraphQL::Types::Boolean
              when :float then ::GraphQL::Types::Float
              when :date then ::Types::DateType
              when :datetime then ::Types::TimeType
              else ::GraphQL::Types::String # :string
              end
            end

            private

            def coerce_parameters(definition, config)
              config[:parameters].to_h do |key, value|
                spec = definition.parameters[key]
                next [key, value] if spec.nil? || value.nil?

                [key, coerce_parameter(spec, value, config[:identifier], key)]
              end
            end

            def coerce_parameter(spec, value, identifier, key)
              scalar = graphql_type(spec[:type])

              if spec[:array]
                Array.wrap(value).map { |item| coerce_value(scalar, item) }
              else
                coerce_value(scalar, value)
              end
            rescue ::GraphQL::CoercionError => e
              raise ::Gitlab::Graphql::Errors::ArgumentError,
                format(s_("AggregationEngine|Invalid value for order parameter `%{param}` of `%{identifier}`: " \
                  "%{error}"), param: key, identifier: identifier, error: e.message)
            end

            # Built-in scalars return nil instead of raising on type mismatch.
            def coerce_value(scalar, value)
              coerced = scalar.coerce_isolated_input(value)
              return coerced unless coerced.nil?

              raise ::GraphQL::CoercionError, "#{value.inspect} is not a valid #{scalar.graphql_name}"
            end

            def build_filter(definition, arguments)
              result = {
                identifier: definition.identifier
              }
              case definition
              when ::Gitlab::Database::Aggregation::ClickHouse::RangeFilter,
                ::Gitlab::Database::Aggregation::ClickHouse::MetricRangeFilter
                from = arguments[:"#{definition.identifier}_from"]
                to = arguments[:"#{definition.identifier}_to"]
                result[:values] = from..to if from || to
              else # ExactMatchFilter / MetricExactMatchFilter
                result[:values] = arguments[definition.identifier]
              end
              result
            end

            def filter_to_arguments(filter)
              case filter
              when ::Gitlab::Database::Aggregation::ClickHouse::RangeFilter,
                ::Gitlab::Database::Aggregation::ClickHouse::MetricRangeFilter
                [[:"#{filter.identifier}_from",
                  graphql_type(filter.type),
                  { required: false, description: "#{filter_description(filter)}. Start of the range." }],
                  [:"#{filter.identifier}_to",
                    graphql_type(filter.type),
                    { required: false, description: "#{filter_description(filter)}. End of the range." }]]
              else # ExactMatchFilter / MetricExactMatchFilter
                [[filter.identifier,
                  [graphql_type(filter.type)],
                  { required: false, description: filter_description(filter) }]]
              end
            end

            def filter_description(filter)
              return filter.description unless filter.metric?

              "#{filter.description} The `#{filter.identifier}` metric must also be requested when using this filter"
            end
          end
        end
      end
    end
  end
end
