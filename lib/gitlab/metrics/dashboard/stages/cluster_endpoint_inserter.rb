# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class ClusterEndpointInserter < BaseStage
          def transform!
            verify_params

            for_metrics do |metric|
              metric[:prometheus_endpoint_path] = endpoint_for_metric(metric)
            end
          end

          private

          def admin_url(metric)
            Gitlab::Routing.url_helpers.prometheus_api_admin_cluster_path(
              params[:cluster],
              proxy_path: query_type(metric),
              query: query_for_metric(metric)
            )
          end

          def endpoint_for_metric(metric)
            case params[:cluster_type]
            when :admin
              admin_url(metric)
            when :group
              error!(_('Group is required when cluster_type is :group')) unless params[:group]
              group_url(metric)
            when :project
              error!(_('Project is required when cluster_type is :project')) unless project
              project_url(metric)
            else
              error!(_('Unrecognized cluster type'))
            end
          end

          def error!(message)
            raise Errors::DashboardProcessingError, message
          end

          def group_url(metric)
            Gitlab::Routing.url_helpers.prometheus_api_group_cluster_path(
              params[:group],
              params[:cluster],
              proxy_path: query_type(metric),
              query: query_for_metric(metric)
            )
          end

          def project_url(metric)
            Gitlab::Routing.url_helpers.prometheus_api_project_cluster_path(
              project,
              params[:cluster],
              proxy_path: query_type(metric),
              query: query_for_metric(metric)
            )
          end

          def query_type(metric)
            metric[:query] ? :query : :query_range
          end

          def query_for_metric(metric)
            query = metric[query_type(metric)]

            raise Errors::MissingQueryError, 'Each "metric" must define one of :query or :query_range' unless query

            query
          end

          def verify_params
            raise Errors::DashboardProcessingError, _('Cluster is required for Stages::ClusterEndpointInserter') unless params[:cluster]
            raise Errors::DashboardProcessingError, _('Cluster type must be specificed for Stages::ClusterEndpointInserter') unless params[:cluster_type]
          end
        end
      end
    end
  end
end
