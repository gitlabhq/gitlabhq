# frozen_string_literal: true

module Banzai
  module Filter
    class InlineClusterMetricsFilter < ::Banzai::Filter::InlineEmbedsFilter
      def embed_params(node)
        url = node['href']
        @query_params = query_params(url)
        return unless [:group, :title, :y_label].all? do |param|
          @query_params.include?(param)
        end

        link_pattern.match(url) { |m| m.named_captures }.symbolize_keys
      end

      def xpath_search
        "descendant-or-self::a[contains(@href,'clusters') and \
          starts-with(@href, '#{gitlab_domain}')]"
      end

      def link_pattern
        ::Gitlab::Metrics::Dashboard::Url.clusters_regex
      end

      def metrics_dashboard_url(params)
        ::Gitlab::Routing.url_helpers.metrics_dashboard_namespace_project_cluster_url(
          params[:namespace],
          params[:project],
          params[:cluster_id],
          # Only Project clusters are supported for now
          # admin and group cluster types may be supported in the future
          cluster_type: :project,
          embedded: true,
          format: :json,
          **@query_params
        )
      end
    end
  end
end
