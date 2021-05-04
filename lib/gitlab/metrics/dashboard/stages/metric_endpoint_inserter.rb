# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class MetricEndpointInserter < BaseStage
          def transform!
            raise Errors::DashboardProcessingError, _('Environment is required for Stages::MetricEndpointInserter') unless params[:environment]

            for_metrics do |metric|
              metric[:prometheus_endpoint_path] = endpoint_for_metric(metric)
            end
          end

          private

          def endpoint_for_metric(metric)
            if params[:sample_metrics]
              Gitlab::Routing.url_helpers.sample_metrics_project_environment_path(
                project,
                params[:environment],
                identifier: metric[:id]
              )
            else
              Gitlab::Routing.url_helpers.prometheus_api_project_environment_path(
                project,
                params[:environment],
                proxy_path: query_type(metric),
                query: query_for_metric(metric)
              )
            end
          end

          def query_type(metric)
            if metric[:query]
              ::Prometheus::ProxyService::PROMETHEUS_QUERY_API.to_sym
            else
              ::Prometheus::ProxyService::PROMETHEUS_QUERY_RANGE_API.to_sym
            end
          end

          def query_for_metric(metric)
            query = metric[query_type(metric)]

            raise Errors::MissingQueryError, 'Each "metric" must define one of :query or :query_range' unless query

            # We need to remove any newlines since our UrlBlocker does not allow
            # multiline URLs.
            query.to_s.squish
          end
        end
      end
    end
  end
end
