module Gitlab
  module CycleAnalytics
    class IssueEvent < BaseEvent
      def initialize(*args)
        @stage = :issue
        @start_time_attrs = issue_table[:created_at]
        @end_time_attrs = [issue_metrics_table[:first_associated_with_milestone_at],
                           issue_metrics_table[:first_added_to_board_at]]
        @projections = [issue_table[:title],
                        issue_table[:iid],
                        issue_table[:id],
                        issue_table[:created_at],
                        issue_table[:author_id]]

        super(*args)
      end

      private

      def serialize(event)
        AnalyticsIssueSerializer.new(project: @project).represent(event).as_json
      end

      def allowed_ids
        @allowed_ids ||= IssuesFinder.new(@options[:current_user], project_id: @project.id).execute.where(id: event_result_ids).pluck(:id)
      end
    end
  end
end
