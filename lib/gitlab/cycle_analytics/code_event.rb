module Gitlab
  module CycleAnalytics
    class CodeEvent < BaseEvent
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

      def self.serialize(event, query)
        event['author'] = User.find(event.delete('author_id'))

        AnalyticsMergeRequestSerializer.new(project: query.project).represent(event).as_json
      end
    end
  end
end
