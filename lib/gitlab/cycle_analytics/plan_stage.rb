# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class PlanStage < BaseStage
      include PlanHelper

      def start_time_attrs
        @start_time_attrs ||= [issue_metrics_table[:first_associated_with_milestone_at],
                               issue_metrics_table[:first_added_to_board_at]]
      end

      def end_time_attrs
        @end_time_attrs ||= issue_metrics_table[:first_mentioned_in_commit_at]
      end

      def name
        :plan
      end

      def title
        s_('CycleAnalyticsStage|Plan')
      end

      def legend
        _("Related Issues")
      end

      def description
        _("Time before an issue starts implementation")
      end
    end
  end
end
