# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class EndpointInserter < BaseStage
          def transform!
            raise Errors::DashboardProcessingError.new('Environment is required for Stages::EndpointInserter') unless params[:environment]

            for_metrics do |metric|
              metric[:prometheus_endpoint_path] = endpoint_for_metric(metric)
            end
          end

          private

          def endpoint_for_metric(metric)
            if ENV['USE_SAMPLE_METRICS']
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
            metric[:query] ? :query : :query_range
          end

          def query_for_metric(metric)
            query = metric[query_type(metric)]

            raise Errors::MissingQueryError.new('Each "metric" must define one of :query or :query_range') unless query

            query
          end
        end
      end
    end
  end
end
