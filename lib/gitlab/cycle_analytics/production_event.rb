module Gitlab
  module CycleAnalytics
    class ProductionEvent < BaseEvent
      @stage = :production
      @start_time_attrs = issue_table[:created_at]

      @end_time_attrs = mr_metrics_table[:first_deployed_to_production_at]

      @projections = [issue_table[:title],
                      issue_table[:iid],
                      issue_table[:id],
                      issue_table[:created_at],
                      issue_table[:author_id]]

      def self.serialize(event, query)
        event['author'] = User.find(event.delete('author_id'))

        AnalyticsIssueSerializer.new(project: query.project).represent(event).as_json
      end
    end
  end
end
