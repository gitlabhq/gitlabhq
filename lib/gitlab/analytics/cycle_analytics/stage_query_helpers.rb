# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageQueryHelpers
        def execute_query(query)
          ActiveRecord::Base.connection.execute(query.to_sql)
        end

        def zero_interval
          Arel::Nodes::NamedFunction.new('CAST', [Arel.sql("'0' AS INTERVAL")])
        end

        def round_duration_to_seconds
          Arel::Nodes::NamedFunction.new('ROUND', [Arel::Nodes::Extract.new(duration, :epoch)])
        end

        def duration
          Arel::Nodes::Subtraction.new(
            stage.end_event.timestamp_projection,
            stage.start_event.timestamp_projection
          )
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def order_by_end_event(query, extra_columns_to_select = [:id])
          ordered_query = query.reorder(stage.end_event.timestamp_projection.desc)

          # When filtering for more than one label, postgres requires the columns in ORDER BY to be present in the GROUP BY clause
          if requires_grouping?
            column_list = [
              *extra_columns_to_select,
              *stage.end_event.column_list,
              *stage.start_event.column_list
            ]

            ordered_query = ordered_query.group(column_list)
          end

          ordered_query
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def requires_grouping?
          Array(params[:label_name]).size > 1
        end
      end
    end
  end
end
