# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class CodeStage < BaseStage
      include CodeHelper

      def start_time_attrs
        @start_time_attrs ||= issue_metrics_table[:first_mentioned_in_commit_at]
      end

      def end_time_attrs
        @end_time_attrs ||= mr_table[:created_at]
      end

      def name
        :code
      end

      def title
        s_('CycleAnalyticsStage|Code')
      end

      def legend
        _("Related Merge Requests")
      end

      def description
        _("Time until first merge request")
      end
    end
  end
end
