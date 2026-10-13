# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class AcquiredCount < BitmapWindow
          def initialize(name, type = :integer, expression = nil, over:, lag_offset: 1, **kwargs)
            super(name, type, expression, operation: :difference, over: over, lag_offset: lag_offset, **kwargs)
          end

          # Project the expression column explicitly, so the inner query keys on it.
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
