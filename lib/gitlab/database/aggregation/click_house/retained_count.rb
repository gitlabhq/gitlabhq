# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class RetainedCount < BitmapWindow
          def initialize(name, type = :integer, expression = nil, over:, lag_offset: 1, **kwargs)
            super(name, type, expression, operation: :intersection, over: over, lag_offset: lag_offset, **kwargs)
          end

          # No inner aggregation: the expression column (ex: user_id) is already
          # projected via the primary key passthrough in the inner query.
          def to_inner_arel(_context)
            nil
          end

          def to_outer_arel(context)
            inner_query_name = context[:inner_query_name]
            bitmap_expr = expression ? expression.call.to_s : name.to_s
            Arel::Nodes::SqlLiteral.new("groupArray(`#{inner_query_name}`.`#{bitmap_expr}`)")
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
