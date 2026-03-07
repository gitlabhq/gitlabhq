# frozen_string_literal: true

module API
  # MLFlow integration API, replicating the Rest API https://www.mlflow.org/docs/latest/rest-api.html#rest-api
  module Ml
    module Mlflow
      class Metrics < ::API::Base
        feature_category :mlops

        helpers ::API::Ml::Mlflow::ApiHelpers

        before do
          check_api_read!
          check_api_write! unless request.get? || request.head?
        end

        resource :metrics do
          desc 'Gets metric history for a run' do
            success Entities::Ml::Mlflow::GetMetricHistory
            detail 'https://www.mlflow.org/docs/2.19.0/rest-api.html#get-metric-history'
            tags ['mlops']
          end
          params do
            requires :run_id, type: String, desc: 'UUID of the run'
            requires :metric_key, type: String, desc: 'Name of the metric'
            optional :max_results, type: Integer,
              desc: 'Maximum number of metrics to return. Default is 1000.',
              default: 1_000
            optional :page_token, type: String, desc: 'Token for pagination'
          end
          get 'get-history', urgency: :low do
            max_results = [params[:max_results], 1_000].min

            finder = ::Projects::Ml::MetricHistoryFinder.new(candidate, params[:metric_key])
            paginator = finder.execute.keyset_paginate(cursor: params[:page_token], per_page: max_results)

            present(
              { metrics: paginator.records, next_page_token: paginator.cursor_for_next_page },
              with: Entities::Ml::Mlflow::GetMetricHistory
            )
          end
        end
      end
    end
  end
end
