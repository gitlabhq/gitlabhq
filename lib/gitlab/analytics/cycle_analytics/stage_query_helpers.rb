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
      end
    end
  end
end
