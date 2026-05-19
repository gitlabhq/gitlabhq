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
