# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that inserts a placeholder element for each
    # reference to a grafana dashboard.
    class InlineGrafanaMetricsFilter < Banzai::Filter::InlineEmbedsFilter
      # Placeholder element for the frontend to use as an
      # injection point for charts.
      def create_element(params)
        begin_loading_dashboard(params[:url])

        doc.document.create_element(
          'div',
          class: 'js-render-metrics',
          'data-dashboard-url': metrics_dashboard_url(params)
        )
      end

      def embed_params(node)
        query_params = Gitlab::Metrics::Dashboard::Url.parse_query(node['href'])
        return unless [:panelId, :from, :to].all? do |param|
          query_params.include?(param)
        end

        { url: node['href'], start: query_params[:from], end: query_params[:to] }
      end

      # Selects any links with an href contains the configured
      # grafana domain for the project
      def xpath_search
        return unless grafana_url.present?

        %(descendant-or-self::a[starts-with(@href, '#{grafana_url}')])
      end

      private

      def project
        context[:project]
      end

      def grafana_url
        project&.grafana_integration&.grafana_url
      end

      def metrics_dashboard_url(params)
        Gitlab::Routing.url_helpers.project_grafana_api_metrics_dashboard_url(
          project,
          embedded: true,
          grafana_url: params[:url],
          start: format_time(params[:start]),
          end: format_time(params[:end])
        )
      end

      # Formats a timestamp from Grafana for compatibility with
      # parsing in JS via `new Date(timestamp)`
      #
      # @param time [String] Represents miliseconds since epoch
      def format_time(time)
        Time.at(time.to_i / 1000).utc.strftime('%FT%TZ')
      end

      # Fetches a dashboard and caches the result for the
      # FE to fetch quickly while rendering charts
      def begin_loading_dashboard(url)
        ::Gitlab::Metrics::Dashboard::Finder.find(
          project,
          embedded: true,
          grafana_url: url
        )
      end
    end
  end
end
