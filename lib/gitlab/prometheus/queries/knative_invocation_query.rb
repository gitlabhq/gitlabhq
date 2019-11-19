# frozen_string_literal: true

module Gitlab
  module Prometheus
    module Queries
      class KnativeInvocationQuery < BaseQuery
        include QueryAdditionalMetrics

        def query(serverless_function_id)
          PrometheusMetricsFinder
            .new(identifier: :system_metrics_knative_function_invocation_count, common: true)
            .execute
            .first
            .to_query_metric
            .tap do |q|
              q.queries[0][:result] = run_query(q.queries[0][:query_range], context(serverless_function_id))
            end
        end

        protected

        def context(function_id)
          function = Serverless::Function.find_by_id(function_id)
          {
            function_name: function.name,
            kube_namespace: function.namespace
          }
        end

        def run_query(query, context)
          query %= context
          client_query_range(query, start: 8.hours.ago.to_f, stop: Time.now.to_f)
        end

        def self.transform_reactive_result(result)
          result[:metrics] = result.delete :data
          result
        end
      end
    end
  end
end
