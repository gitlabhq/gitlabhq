module Gitlab
  module Prometheus
    module AdditionalMetricsParser
      extend self

      def load_groups_from_yaml
        additional_metrics_raw.map(&method(:group_from_entry))
      end

      private

      def metrics_from_list(list)
        list.map { |entry| metric_from_entry(entry) }
      end

      def metric_from_entry(entry)
        required_fields = [:title, :required_metrics, :weight, :queries]
        missing_fields = required_fields.select { |key| entry[key].nil? }
        raise ParsingError.new("entry missing required fields #{missing_fields}") unless missing_fields.empty?

        Metric.new(entry[:title], entry[:required_metrics], entry[:weight], entry[:y_label], entry[:queries])
      end

      def group_from_entry(entry)
        required_fields = [:group, :priority, :metrics]
        missing_fields = required_fields.select { |key| entry[key].nil? }

        raise ParsingError.new("entry missing required fields #{missing_fields.map(&:to_s)}") unless missing_fields.empty?

        group = MetricGroup.new(entry[:group], entry[:priority])
        group.tap { |g| g.metrics = metrics_from_list(entry[:metrics]) }
      end

      def additional_metrics_raw
        @additional_metrics_raw ||= load_yaml_file&.map(&:deep_symbolize_keys).freeze
      end

      def load_yaml_file
        YAML.load_file(Rails.root.join('config/additional_metrics.yml'))
      end
    end
  end
end
