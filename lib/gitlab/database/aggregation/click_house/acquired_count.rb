# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class AcquiredCount < BitmapWindow
          def initialize(name, type = :integer, expression = nil, over:, lag_offset: 1, **kwargs)
            super(name, type, expression, operation: :difference, over: over, lag_offset: lag_offset, **kwargs)
          end

          # Project the expression column (ex: user_id) explicitly rather than relying on
          # the primary key passthrough, which only covers it for tables that happen to
          # sort by it. GROUP BY ALL adds it to the inner grouping key, and the :difference
          # operation applies arrayDistinct, so repeated values do not inflate the count.
          def to_inner_arel(context)
            expression ? expression.call : context[:scope][source_column]
          end

          def to_outer_arel(context)
            inner_query_name = context[:inner_query_name]
            local_alias = context.fetch(:local_alias, name)
            Arel::Nodes::SqlLiteral.new("groupArray(`#{inner_query_name}`.`#{local_alias}`)")
          end

          # Already Array(UInt64) from to_outer_arel so no finalization needed.
          def finalization_sql(alias_name)
            alias_name
          end
        end
      end
    end
  end
end
