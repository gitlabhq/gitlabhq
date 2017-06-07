module Gitlab
  module Prometheus
    module AdditionalMetricsParser
      extend self

      def load_groups_from_yaml
        additional_metrics_raw.map(&method(:new))
      end

      private

      def metrics_from_list(list)
        list.map { |entry| metric_from_entry(entry) }
      end

      def metric_from_entry(entry)
        missing_fields = [:title, :required_metrics, :weight, :queries].select { |key| !entry.key?(key) }
        raise ParsingError.new("entry missing required fields #{missing_fields}") unless missing_fields.empty?

        Metric.new(entry[:title], entry[:required_metrics], entry[:weight], entry[:y_label], entry[:queries])
      end

      def group_from_entry(entry)
        missing_fields = [:group, :priority, :metrics].select { |key| !entry.key?(key) }
        raise ParsingError.new("entry missing required fields #{missing_fields}") unless missing_fields.empty?

        group = MetricGroup.new(entry[:group], entry[:priority])
        group.tap { |g| g.metrics = Metric.metrics_from_list(entry[:metrics]) }
      end

      def additional_metrics_raw
        @additional_metrics_raw ||= YAML.load_file(Rails.root.join('config/additional_metrics.yml'))&.map(&:deep_symbolize_keys).freeze
      end
    end
  end
end
