module Gitlab
  module CycleAnalytics
    class TestEvent < BaseEvent
      @start_time_attrs = mr_table[:created_at]

      @end_time_attrs = mr_metrics_table[:merged_at]

      @projections = [mr_table[:title],
                      mr_table[:iid],
                      mr_table[:id],
                      mr_table[:created_at],
                      mr_table[:state],
                      mr_table[:author_id]]
    end
  end
end
