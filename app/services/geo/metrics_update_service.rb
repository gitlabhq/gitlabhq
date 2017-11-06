module Geo
  class MetricsUpdateService
    METRIC_PREFIX = 'geo_'.freeze

    def execute
      return unless Gitlab::Geo.enabled?

      if Gitlab::Geo.primary?
        fetch_secondary_geo_nodes_metrics
      else
        fetch_current_geo_node_metrics
      end
    end

    private

    def fetch_secondary_geo_nodes_metrics
      Gitlab::Geo.secondary_nodes.find_each { |node| fetch_geo_node_metrics(node) }
    end

    def fetch_current_geo_node_metrics
      fetch_geo_node_metrics(Gitlab::Geo.current_node)
    end

    def fetch_geo_node_metrics(node)
      status = node_status(node)

      unless status.success
        increment_failed_status_counter(node)
        return
      end

      NodeStatusService::STATUS_DATA.each do |key, docstring|
        value = status[key]

        next unless value.is_a?(Integer)

        gauge = Gitlab::Metrics.gauge(gauge_metric_name(key), docstring, {}, :max)
        gauge.set(metric_labels(node), value)
      end

      set_last_updated_at(node)
    end

    def node_status(node)
      NodeStatusService.new.call(node)
    end

    def set_last_updated_at(node)
      gauge = Gitlab::Metrics.gauge(
        :geo_status_last_updated_timestamp,
        'UNIX timestamp of last time Geo node status was updated internally',
        {},
        :max)

      gauge.set(metric_labels(node), Time.now.to_i)
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
