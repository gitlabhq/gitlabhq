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
              "count_#{parse_target_and_source(column, relation)}"
            end

            def distinct_count(relation, column = nil, batch: true, batch_size: nil, start: nil, finish: nil)
              "count_distinct_#{parse_target_and_source(column, relation)}"
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
              "sum_#{parse_target_and_source(column, relation)}"
            end

            def estimate_batch_distinct_count(relation, column = nil, *rest)
              "estimate_distinct_#{parse_target_and_source(column, relation)}"
            end

            def add(*args)
              "add_#{args.join('_and_')}"
            end

            def parse_target_and_source(column, relation)
              if column
                "#{column}_from_#{relation.table_name}"
              else
                relation.table_name
              end
            end
          end
        end
      end
    end
  end
end
