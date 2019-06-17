# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class IssueStage < BaseStage
      include IssueHelper

      def start_time_attrs
        @start_time_attrs ||= issue_table[:created_at]
      end

      def end_time_attrs
        @end_time_attrs ||= [issue_metrics_table[:first_associated_with_milestone_at],
                             issue_metrics_table[:first_added_to_board_at]]
      end

      def name
        :issue
      end

      def title
        s_('CycleAnalyticsStage|Issue')
      end

      def legend
        _("Related Issues")
      end

      def description
        _("Time before an issue gets scheduled")
      end
    end
  end
end
