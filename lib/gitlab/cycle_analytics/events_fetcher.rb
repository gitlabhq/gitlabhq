module Gitlab
  module CycleAnalytics
    class EventsFetcher
      include MetricsFetcher

      def initialize(project:, from:)
        @project = project
        @from = from
      end

      def fetch_issues
        cte_table = Arel::Table.new("cte_table_for_issue")

        interval_query = Arel::Nodes::As.new(
          cte_table,
          subtract_datetimes(base_query_for(:issue), *attributes, 'issue'))

        #TODO ActiveRecord::Base.connection.execute(interval_query)
      end

      def attributes
        [issue_metrics_table[:first_associated_with_milestone_at],
         issue_metrics_table[:first_added_to_board_at]]
      end
    end
  end
end
