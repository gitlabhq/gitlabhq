module Gitlab
  module Prometheus
    module Queries
      module QueryAdditionalMetrics
        def query_metrics(project, query_context)
          matched_metrics(project).map(&query_group(query_context))
            .select(&method(:group_with_any_metrics))
        end

        protected

        def query_group(query_context)
          query_processor = method(:process_query).curry[query_context]

          lambda do |group|
            metrics = group.metrics.map do |metric|
              {
                title: metric.title,
                weight: metric.weight,
                y_label: metric.y_label,
                queries: metric.queries.map(&query_processor).select(&method(:query_with_result))
              }
            end

            {
              group: group.name,
              priority: group.priority,
              metrics: metrics.select(&method(:metric_with_any_queries))
            }
          end
        end

        private

        def metric_with_any_queries(metric)
          metric[:queries]&.count&.> 0
        end

        def group_with_any_metrics(group)
          group[:metrics]&.count&.> 0
        end

        def query_with_result(query)
          query[:result]&.any? do |item|
            item&.[](:values)&.any? || item&.[](:value)&.any?
          end
        end

        def process_query(context, query)
          query = query.dup
          result =
            if query.key?(:query_range)
              query[:query_range] %= context
              client_query_range(query[:query_range], start: context[:timeframe_start], stop: context[:timeframe_end])
            else
              query[:query] %= context
              client_query(query[:query], time: context[:timeframe_end])
            end

          query[:result] = result&.map(&:deep_symbolize_keys)
          query
        end

        def available_metrics
          @available_metrics ||= client_label_values || []
        end

        def matched_metrics(project)
          result = Gitlab::Prometheus::MetricGroup.for_project(project).map do |group|
            group.metrics.select! do |metric|
              metric.required_metrics.all?(&available_metrics.method(:include?))
            end
            group
          end

          result.select { |group| group.metrics.any? }
        end

        def common_query_context(environment, timeframe_start:, timeframe_end:)
          base_query_context(timeframe_start, timeframe_end).merge({
            ci_environment_slug: environment.slug,
            kube_namespace: environment.deployment_platform&.actual_namespace || '',
            environment_filter: %{container_name!="POD",environment="#{environment.slug}"}
          })
        end

        def base_query_context(timeframe_start, timeframe_end)
          {
            timeframe_start: timeframe_start,
            timeframe_end: timeframe_end
          }
        end
      end
    end
  end
end
