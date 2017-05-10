module Gitlab::Prometheus::Queries
  class AdditionalMetricsQuery < BaseQuery
    def self.metrics
      @metrics ||= YAML.load_file(Rails.root.join('config/custom_metrics.yml')).freeze
    end

    def query(environment_id)
      environment = Environment.find_by(id: environment_id)

      context = {
        environment_slug: environment.slug,
        environment_filter: %{container_name!="POD",environment="#{environment.slug}"}
      }

      timeframe_start = 8.hours.ago.to_f
      timeframe_end = Time.now.to_f

      matched_metrics.map do |group|
        group[:metrics].map! do |metric|
          metric[:queries].map! do |query|
            query = query.symbolize_keys
            query[:result] =
              if query.has_key?(:query_range)
                client_query_range(query[:query_range] % context, start: timeframe_start, stop: timeframe_end)
              else
                client_query(query[:query] % context, time: timeframe_end)
              end
            query
          end
          metric
        end
        group
      end
    end

    def process_query(group, query)
      result = if query.has_key?(:query_range)
                 client_query_range(query[:query_range] % context, start: timeframe_start, stop: timeframe_end)
               else
                 client_query(query[:query] % context, time: timeframe_end)
               end
      contains_metrics = result.all? do |item|
        item&.[](:values)&.any? || item&.[](:value)&.any?
      end
    end

    def process_result(query_result)
      contains_metrics = query_result.all? do |item|
        item&.[](:values)&.any? || item&.[](:value)&.any?
      end

      contains_metrics
    end

    def matched_metrics
      label_values = client_label_values || []

      result = Gitlab::Prometheus::MetricsSources.additional_metrics.map do |group|
        group[:metrics].map!(&:symbolize_keys)
        group[:metrics].select! do |metric|
          matcher = Regexp.compile(metric[:detect])
          label_values.any? &matcher.method(:match)
        end
        group
      end

      result.select {|group| !group[:metrics].empty?}
    end
  end
end
