module Gitlab::Prometheus
  class Metric
    attr_reader :group, :title, :required_metrics, :weight, :y_label, :queries

    def initialize(title, required_metrics, weight, y_label, queries = [])
      @title = title
      @required_metrics = required_metrics
      @weight = weight
      @y_label = y_label || 'Values'
      @queries = queries
    end

    def self.metric_from_entry(entry)
      missing_fields = [:title, :required_metrics, :weight, :queries].select { |key| !entry.has_key?(key) }
      raise ParsingError.new("entry missing required fields #{missing_fields}") unless missing_fields.empty?

      Metric.new(entry[:title], entry[:required_metrics], entry[:weight], entry[:y_label], entry[:queries])
    end

    def self.metrics_from_list(list)
      list.map { |entry| metric_from_entry(entry) }
    end
  end
end
