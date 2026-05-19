# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class MetricExactMatchFilter < MetricFilterDefinition
          def apply_outer(query_builder, filter_config, metric_column)
            query_builder.having(metric_column.in(filter_config[:values]))
          end
        end
      end
    end
  end
end
