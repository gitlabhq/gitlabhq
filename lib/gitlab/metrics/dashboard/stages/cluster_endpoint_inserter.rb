# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class ClusterEndpointInserter < BaseStage
          def transform!
            verify_params
          end

          private

          def error!(message)
            raise Errors::DashboardProcessingError, message
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
            raise Errors::DashboardProcessingError, _('Cluster type must be specified for Stages::ClusterEndpointInserter') unless params[:cluster_type]
          end
        end
      end
    end
  end
end
