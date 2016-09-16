class CycleAnalytics
  module TableReferences
    class << self
      def issues
        Issue.arel_table
      end

      def issue_metrics
        Issue::Metrics.arel_table
      end

      def merge_requests
        MergeRequest.arel_table
      end

      def merge_request_metrics
        MergeRequest::Metrics.arel_table
      end

      def merge_requests_closing_issues
        MergeRequestsClosingIssues.arel_table
      end
    end
  end
end
