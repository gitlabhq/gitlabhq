module Gitlab::Prometheus
  class Metric
    attr_reader :group, :title, :detect, :weight, :queries

    def initialize(group, title, detect, weight, queries = [])
      @group = group
      @title = title
      @detect = detect
      @weight = weight
      @queries = queries
    end

    def self.metric_from_entry(group, entry)
      missing_fields = [:title, :detect, :weight, :queries].select { |key| !entry.has_key?(key) }
      raise ParsingError.new("entry missing required fields #{missing_fields}") unless missing_fields.empty?

      Metric.new(group, entry[:title], entry[:detect], entry[:weight], entry[:queries])
    end

    def self.metrics_from_list(group, list)
      list.map { |entry| metric_from_entry(group, entry) }
    end

    def self.additional_metrics_raw
      @additional_metrics_raw ||= YAML.load_file(Rails.root.join('config/additional_metrics.yml')).map(&:deep_symbolize_keys)
    end
  end
end
