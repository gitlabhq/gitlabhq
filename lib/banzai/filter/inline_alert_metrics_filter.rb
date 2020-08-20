# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that inserts a placeholder element for each
    # reference to an alert dashboard.
    class InlineAlertMetricsFilter < ::Banzai::Filter::InlineEmbedsFilter
      include ::Gitlab::Routing
      # Search params for selecting alert metrics links. A few
      # simple checks is enough to boost performance without
      # the cost of doing a full regex match.
      def xpath_search
        "descendant-or-self::a[contains(@href,'metrics_dashboard') and \
          contains(@href,'prometheus/alerts') and \
          starts-with(@href, '#{gitlab_domain}')]"
      end

      # Regular expression matching alert dashboard urls
      def link_pattern
        ::Gitlab::Metrics::Dashboard::Url.alert_regex
      end

      private

      # Endpoint FE should hit to collect the appropriate
      # chart information
      def metrics_dashboard_url(params)
        metrics_dashboard_namespace_project_prometheus_alert_url(
          params['namespace'],
          params['project'],
          params['alert'],
          embedded: true,
          format: :json,
          **query_params(params['url'])
        )
      end

      # Parses query params out from full url string into hash.
      #
      # Ex) 'https://<root>/<project>/metrics_dashboard?title=Title&group=Group'
      #       --> { title: 'Title', group: 'Group' }
      def query_params(url)
        ::Gitlab::Metrics::Dashboard::Url.parse_query(url)
      end
    end
  end
end
