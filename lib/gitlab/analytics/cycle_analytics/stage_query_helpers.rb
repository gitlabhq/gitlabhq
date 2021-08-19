# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageQueryHelpers
        def execute_query(query)
          ApplicationRecord.connection.execute(query.to_sql)
        end

        def zero_interval
          Arel::Nodes::NamedFunction.new('CAST', [Arel.sql("'0' AS INTERVAL")])
        end

        def round_duration_to_seconds
          Arel::Nodes::NamedFunction.new('ROUND', [Arel::Nodes::Extract.new(duration, :epoch)])
        end

        def duration
          Arel::Nodes::Subtraction.new(
            end_event_timestamp_projection,
            stage.start_event.timestamp_projection
          )
        end

        def end_event_timestamp_projection
          if in_progress?
            Arel::Nodes::NamedFunction.new('TO_TIMESTAMP', [Time.current.to_i])
          else
            stage.end_event.timestamp_projection
          end
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def order_by(query, sort, direction, extra_columns_to_select = [:id])
          ordered_query = Gitlab::Analytics::CycleAnalytics::Sorting.new(stage: stage, query: query, params: params).apply(sort, direction)

          # When filtering for more than one label, postgres requires the columns in ORDER BY to be present in the GROUP BY clause
          if requires_grouping?
            column_list = [].tap do |array|
              array.concat(extra_columns_to_select)
              array.concat(stage.end_event.column_list) unless in_progress?
              array.concat(stage.start_event.column_list)
            end

            ordered_query = ordered_query.group(column_list)
          end

          ordered_query
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def requires_grouping?
          Array(params[:label_name]).size > 1
        end

        def in_progress?
          params[:end_event_filter] == :in_progress
        end
      end
    end
  end
end
