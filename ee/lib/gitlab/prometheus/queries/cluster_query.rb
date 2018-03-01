module Gitlab
  module Prometheus
    module Queries
      class ClusterQuery < BaseQuery
        include QueryAdditionalMetrics

        def query
          AdditionalMetricsParser.load_groups_from_yaml('cluster_metrics.yml')
            .map(&query_group(base_query_context(8.hours.ago, Time.now)))
        end
      end
    end
  end
end
