module Gitlab::Prometheus::Queries
  class AdditionalMetricsQuery < BaseQuery
    def query(environment_id)
      query_processor = method(:process_query).curry[query_context(environment_id)]

      matched_metrics.map do |group|
        metrics = group.metrics.map do |metric|
          {
            title: metric.title,
            weight: metric.weight,
            queries: metric.queries.map(&query_processor)
          }
        end

        {
          group: group.name,
          priority: group.priority,
          metrics: metrics
        }
      end
    end

    private

    def query_context(environment_id)
      environment = Environment.find_by(id: environment_id)
      {
        environment_slug: environment.slug,
        environment_filter: %{container_name!="POD",environment="#{environment.slug}"},
        timeframe_start: 8.hours.ago.to_f,
        timeframe_end: Time.now.to_f
      }
    end

    def process_query(context, query)
      query_with_result = query.dup
      query_with_result[:result] =
        if query.has_key?(:query_range)
          client_query_range(query[:query_range] % context, start: context[:timeframe_start], stop: context[:timeframe_end])
        else
          client_query(query[:query] % context, time: context[:timeframe_end])
        end
      query_with_result
    end

    def process_result(query_result)
      contains_metrics = query_result.all? do |item|
        item&.[](:values)&.any? || item&.[](:value)&.any?
      end

      contains_metrics
    end

    def matched_metrics
      label_values = client_label_values || []
      Gitlab::Prometheus::MetricGroup.all

      result = Gitlab::Prometheus::MetricGroup.all.map do |group|
        group.metrics.select! do |metric|
          matcher = Regexp.compile(metric.detect)
          label_values.any? &matcher.method(:match)
        end
        group
      end

      result.select { |group| group.metrics.any? }
    end
  end
end
