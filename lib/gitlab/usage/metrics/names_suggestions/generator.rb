# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module NamesSuggestions
        class Generator < ::Gitlab::UsageData
          FREE_TEXT_METRIC_NAME = "<please fill metric name>"

          class << self
            def generate(key_path)
              uncached_data.deep_stringify_keys.dig(*key_path.split('.'))
            end

            private

            def count(relation, column = nil, batch: true, batch_size: nil, start: nil, finish: nil)
              name_suggestion(column: column, relation: relation, prefix: 'count')
            end

            def distinct_count(relation, column = nil, batch: true, batch_size: nil, start: nil, finish: nil)
              name_suggestion(column: column, relation: relation, prefix: 'count_distinct', distinct: :distinct)
            end

            def redis_usage_counter
              FREE_TEXT_METRIC_NAME
            end

            def alt_usage_data(*)
              FREE_TEXT_METRIC_NAME
            end

            def redis_usage_data_totals(counter)
              counter.fallback_totals.transform_values { |_| FREE_TEXT_METRIC_NAME}
            end

            def sum(relation, column, *rest)
              name_suggestion(column: column, relation: relation, prefix: 'sum')
            end

            def estimate_batch_distinct_count(relation, column = nil, *rest)
              name_suggestion(column: column, relation: relation, prefix: 'estimate_distinct_count')
            end

            def add(*args)
              "add_#{args.join('_and_')}"
            end

            def name_suggestion(relation:, column: nil, prefix: nil, distinct: nil)
              parts = [prefix]

              if column
                parts << parse_target(column)
                parts << 'from'
              end

              source = parse_source(relation)
              constraints = parse_constraints(relation: relation, column: column, distinct: distinct)

              if constraints.include?(source)
                parts << "<adjective describing: '#{constraints}'>"
              end

              parts << source
              parts.compact.join('_')
            end

            def parse_constraints(relation:, column: nil, distinct: nil)
              connection = relation.connection
              ::Gitlab::Usage::Metrics::NamesSuggestions::RelationParsers::Constraints
                .new(connection)
                .accept(arel(relation: relation, column: column, distinct: distinct), collector(connection))
                .value
            end

            def parse_target(column)
              if column.is_a?(Arel::Attribute)
                "#{column.relation.name}.#{column.name}"
              else
                column
              end
            end

            def parse_source(relation)
              relation.table_name
            end

            def collector(connection)
              Arel::Collectors::SubstituteBinds.new(connection, Arel::Collectors::SQLString.new)
            end

            def arel(relation:, column: nil, distinct: nil)
              column ||= relation.primary_key

              if column.is_a?(Arel::Attribute)
                relation.select(column.count(distinct)).arel
              else
                relation.select(relation.all.table[column].count(distinct)).arel
              end
            end
          end
        end
      end
    end
  end
end
