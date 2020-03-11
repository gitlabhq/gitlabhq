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

        super
      end

      # @return [Hash<Symbol, String>] with keys :grafana_url, :start, and :end
      def embed_params(node)
        query_params = Gitlab::Metrics::Dashboard::Url.parse_query(node['href'])

        time_window = Grafana::TimeWindow.new(query_params[:from], query_params[:to])
        url = url_with_window(node['href'], query_params, time_window.in_milliseconds)

        { grafana_url: url }.merge(time_window.formatted)
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
          **params
        )
      end

      # If the provided url is missing time window parameters,
      # this inserts the default window into the url, allowing
      # the embed service to correctly format prometheus
      # queries during embed processing.
      #
      # @param url [String]
      # @param query_params [Hash<Symbol, String>]
      # @param time_window_params [Hash<Symbol, Integer>]
      # @return [String]
      def url_with_window(url, query_params, time_window_params)
        uri = URI(url)
        uri.query = time_window_params.merge(query_params).to_query

        uri.to_s
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
