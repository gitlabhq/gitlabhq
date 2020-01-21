# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class ProductionStage < BaseStage
      include ProductionHelper

      def start_time_attrs
        @start_time_attrs ||= issue_table[:created_at]
      end

      def end_time_attrs
        @end_time_attrs ||= mr_metrics_table[:first_deployed_to_production_at]
      end

      def name
        :production
      end

      def title
        s_('CycleAnalyticsStage|Total')
      end

      def legend
        _("Related Issues")
      end

      def description
        _("From issue creation until deploy to production")
      end

      def query
        # Limit to merge requests that have been deployed to production after `@from`
        query.where(mr_metrics_table[:first_deployed_to_production_at].gteq(@from))
      end
    end
  end
end
