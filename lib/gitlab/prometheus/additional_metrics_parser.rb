module Gitlab
  module Prometheus
    module AdditionalMetricsParser
      extend self

      def load_groups_from_yaml
        additional_metrics_raw.map(&method(:group_from_entry))
      end

      private

      def validate!(obj)
        raise ParsingError.new(obj.errors.full_messages.join('\n')) unless obj.valid?
      end

      def group_from_entry(entry)
        entry[:name] = entry.delete(:group)
        entry[:metrics]&.map! do |entry|
          Metric.new(entry).tap(&method(:validate!))
        end

        MetricGroup.new(entry).tap(&method(:validate!))
      end

      def additional_metrics_raw
        load_yaml_file&.map(&:deep_symbolize_keys).freeze
      end

      def load_yaml_file
        @loaded_yaml_file ||= YAML.load_file(Rails.root.join('config/prometheus/additional_metrics.yml'))
      end
    end
  end
end
