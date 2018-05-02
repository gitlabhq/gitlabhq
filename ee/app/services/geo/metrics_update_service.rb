module Geo
  class MetricsUpdateService
    METRIC_PREFIX = 'geo_'.freeze

    def execute
      return unless Gitlab::Geo.enabled?

      if Gitlab::Geo.primary?
        fetch_secondary_geo_nodes_metrics
      end

      fetch_current_geo_node_metrics
    end

    private

    def fetch_secondary_geo_nodes_metrics
      Gitlab::Geo.secondary_nodes.find_each { |node| fetch_geo_node_metrics(node) }
    end

    def fetch_current_geo_node_metrics
      fetch_geo_node_metrics(Gitlab::Geo.current_node)
    end

    def fetch_geo_node_metrics(node)
      return unless node&.enabled?

      status = node_status(node)

      unless status.success
        increment_failed_status_counter(node)
        return
      end

      update_db_metrics(node, status) if Gitlab::Geo.primary?
      status.update_cache! if node.current?
      update_prometheus_metrics(node, status) if Gitlab::Metrics.prometheus_metrics_enabled?
    end

    def update_db_metrics(node, status)
      db_status = node.find_or_build_status

      db_status.update_attributes(status.attributes.compact.merge(last_successful_status_check_at: Time.now.utc))
    end

    def update_prometheus_metrics(node, status)
      GeoNodeStatus::PROMETHEUS_METRICS.each do |column, docstring|
        value = status[column]

        next unless value.is_a?(Integer)

        gauge = Gitlab::Metrics.gauge(gauge_metric_name(column), docstring, {}, :max)
        gauge.set(metric_labels(node), value)
      end
    end

    def node_status(node)
      NodeStatusFetchService.new.call(node)
    end

    def increment_failed_status_counter(node)
      failed_status_counter(node).increment
    end

    def failed_status_counter(node)
      Gitlab::Metrics.counter(
        :geo_status_failed_total,
        'Total number of times status for Geo node failed to retrieve',
        metric_labels(node))
    end

    def gauge_metric_name(name)
      # Prometheus naming conventions in
      # https://prometheus.io/docs/instrumenting/writing_exporters/#naming says
      # that _count and _total should be reserved for counters
      base_name = name.to_s.gsub(/(_count|_total)$/, '')

      (METRIC_PREFIX + base_name).to_sym
    end

    def metric_labels(node)
      { url: node.url }
    end
  end
end
