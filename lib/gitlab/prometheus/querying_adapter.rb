module Gitlab
  module Prometheus
    class QueryingAdapter
      attr_reader :cache_source

      def initialize(cache_source)
        @cache_source = cache_source
      end

      def with_reactive_cache(*args)
        cache_source.with_reactive_cache(*args)
      end

      def environment_metrics(environment)
        with_reactive_cache(Gitlab::Prometheus::Queries::EnvironmentQuery.name, environment.id, &method(:rename_data_to_metrics))
      end

      def deployment_metrics(deployment)
        metrics = with_reactive_cache(Gitlab::Prometheus::Queries::DeploymentQuery.name, deployment.environment.id, deployment.id, &method(:rename_data_to_metrics))
        metrics&.merge(deployment_time: deployment.created_at.to_i) || {}
      end

      def additional_environment_metrics(environment)
        with_reactive_cache(Gitlab::Prometheus::Queries::AdditionalMetricsEnvironmentQuery.name, environment.id, &:itself)
      end

      def additional_deployment_metrics(deployment)
        with_reactive_cache(Gitlab::Prometheus::Queries::AdditionalMetricsDeploymentQuery.name, deployment.environment.id, deployment.id, &:itself)
      end

      def matched_metrics
        with_reactive_cache(Gitlab::Prometheus::Queries::MatchedMetricsQuery.name, nil, &:itself)
      end

      # Cache metrics for specific environment
      def self.calculate_reactive_cache(client, query_class_name, environment_id, *args)
        return unless active? && project && !project.pending_delete?

        data = Kernel.const_get(query_class_name).new(client).query(environment_id, *args)
        {
          success: true,
          data: data,
          last_update: Time.now.utc
        }
      rescue Gitlab::PrometheusError => err
        { success: false, result: err.message }
      end

      private

      def rename_data_to_metrics(metrics)
        metrics[:metrics] = metrics.delete :data
        metrics
      end
    end
  end
end
