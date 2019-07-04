# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module MetricsTables
      def mr_metrics_table
        MergeRequest::Metrics.arel_table
      end

      def mr_table
        MergeRequest.arel_table
      end

      def mr_diff_table
        MergeRequestDiff.arel_table
      end

      def mr_diff_commits_table
        MergeRequestDiffCommit.arel_table
      end

      def mr_closing_issues_table
        MergeRequestsClosingIssues.arel_table
      end

      def issue_table
        Issue.arel_table
      end

      def issue_metrics_table
        Issue::Metrics.arel_table
      end

      def user_table
        User.arel_table
      end

      def projects_table
        Project.arel_table
      end

      def routes_table
        Route.arel_table
      end

      def build_table
        ::CommitStatus.arel_table
      end
    end
  end
end
