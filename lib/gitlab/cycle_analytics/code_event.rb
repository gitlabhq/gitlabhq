module Gitlab
  module CycleAnalytics
    class CodeEvent < BaseEvent
      include MergeRequestAllowed

      def initialize(*args)
        @stage = :code
        @start_time_attrs = issue_metrics_table[:first_mentioned_in_commit_at]
        @end_time_attrs = mr_table[:created_at]
        @projections = [mr_table[:title],
                        mr_table[:iid],
                        mr_table[:id],
                        mr_table[:created_at],
                        mr_table[:state],
                        mr_table[:author_id]]
        @order = mr_table[:created_at]

        super(*args)
      end

      private

      def serialize(event)
        AnalyticsMergeRequestSerializer.new(project: @project).represent(event).as_json
      end
    end
  end
end
