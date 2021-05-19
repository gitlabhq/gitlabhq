# frozen_string_literal: true

module Gitlab
  module Prometheus
    module AdditionalMetricsParser
      CONFIG_ROOT = 'config/prometheus'
      MUTEX = Mutex.new
      extend self

      def load_groups_from_yaml(file_name)
        yaml_metrics_raw(file_name).map(&method(:group_from_entry))
      end

      private

      def validate!(obj)
        raise ParsingError, obj.errors.full_messages.join('\n') unless obj.valid?
      end

      def group_from_entry(entry)
        entry[:name] = entry.delete(:group)
        entry[:metrics]&.map! do |entry|
          Metric.new(entry).tap(&method(:validate!))
        end

        MetricGroup.new(entry).tap(&method(:validate!))
      end

      def yaml_metrics_raw(file_name)
        load_yaml_file(file_name)&.map(&:deep_symbolize_keys).freeze
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def load_yaml_file(file_name)
        return YAML.load_file(Rails.root.join(CONFIG_ROOT, file_name)) if Rails.env.development?

        MUTEX.synchronize do
          @loaded_yaml_cache ||= {}
          @loaded_yaml_cache[file_name] ||= YAML.load_file(Rails.root.join(CONFIG_ROOT, file_name))
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
