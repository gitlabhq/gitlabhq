# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that inserts a placeholder element for each
    # reference to a metrics dashboard.
    class InlineMetricsFilter < Banzai::Filter::InlineEmbedsFilter
      # Placeholder element for the frontend to use as an
      # injection point for charts.
      def create_element(params)
        doc.document.create_element(
          'div',
          class: 'js-render-metrics',
          'data-dashboard-url': metrics_dashboard_url(params)
        )
      end

      # Endpoint FE should hit to collect the appropriate
      # chart information
      def metrics_dashboard_url(params)
        Gitlab::Metrics::Dashboard::Url.build_dashboard_url(
          params['namespace'],
          params['project'],
          params['environment'],
          embedded: true
        )
      end

      # Search params for selecting metrics links. A few
      # simple checks is enough to boost performance without
      # the cost of doing a full regex match.
      def xpath_search
        "descendant-or-self::a[contains(@href,'metrics') and \
          starts-with(@href, '#{Gitlab.config.gitlab.url}')]"
      end

      # Regular expression matching metrics urls
      def link_pattern
        Gitlab::Metrics::Dashboard::Url.regex
      end
    end
  end
end
