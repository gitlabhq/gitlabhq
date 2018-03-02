module Gitlab
  module CycleAnalytics
    class TestStage < BaseStage
      def start_time_attrs
        @start_time_attrs ||= mr_metrics_table[:latest_build_started_at]
      end

      def end_time_attrs
        @end_time_attrs ||= mr_metrics_table[:latest_build_finished_at]
      end

      def name
        :test
      end

      def title
        s_('CycleAnalyticsStage|Test')
      end

      def legend
        _("Related Jobs")
      end

      def description
        _("Total test time for all commits/merges")
      end

      def stage_query(project_ids)
        if @options[:branch]
          super(project_ids).where(build_table[:ref].eq(@options[:branch]))
        else
          super(project_ids)
        end
      end
    end
  end
end
