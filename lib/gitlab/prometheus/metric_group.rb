module Gitlab::Prometheus
  class MetricGroup
    attr_reader :priority, :name
    attr_accessor :metrics

    def initialize(name, priority, metrics = [])
      @name = name
      @priority = priority
      @metrics = metrics
    end

    def self.all
      load_groups_from_yaml
    end

    def self.group_from_entry(entry)
      missing_fields = [:group, :priority, :metrics].select { |key| !entry.has_key?(key) }
      raise ParsingError.new("entry missing required fields #{missing_fields}") unless missing_fields.empty?

      group = MetricGroup.new(entry[:group], entry[:priority])
      group.metrics = Metric.metrics_from_list(group, entry[:metrics])
      group
    end

    def self.load_groups_from_yaml
      additional_metrics_raw.map(&method(:group_from_entry))
    end

    def self.additional_metrics_raw
      @additional_metrics_raw ||= YAML.load_file(Rails.root.join('config/additional_metrics.yml'))&.map(&:deep_symbolize_keys).freeze
    end
  end
end
