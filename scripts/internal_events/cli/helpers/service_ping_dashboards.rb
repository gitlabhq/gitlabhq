# frozen_string_literal: true

# Helpers for generating service ping exploration dashboards links
module InternalEventsCli
  module Helpers
    module ServicePingDashboards
      def metric_exploration_group_path(product_group, stage_name)
        "#{tableau_base_path}/MetricExplorationbyGroup?Group%20Name=#{product_group}&Stage%20Name=#{stage_name}"
      end

      def metric_trend_path(key_path)
        "#{tableau_base_path}/MetricTrend?Metrics%20Path=#{key_path}"
      end

      private

      def tableau_base_path
        @tableau_base_path ||= 'https://10az.online.tableau.com/#/site/gitlab/views/PDServicePingExplorationDashboard'
      end
    end
  end
end
