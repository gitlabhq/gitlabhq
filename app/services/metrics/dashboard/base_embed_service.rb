# frozen_string_literal: true

# Base class for embed services. Contains a few basic helper
# methods that the embed services share.
module Metrics
  module Dashboard
    class BaseEmbedService < ::Metrics::Dashboard::BaseService
      def cache_key
        "dynamic_metrics_dashboard_#{identifiers}"
      end

      protected

      def dashboard_path
        params[:dashboard_path].presence ||
          ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH
      end

      def group
        params[:group]
      end

      def title
        params[:title]
      end

      def y_label
        params[:y_label]
      end

      def identifiers
        [dashboard_path, group, title, y_label].join('|')
      end
    end
  end
end
