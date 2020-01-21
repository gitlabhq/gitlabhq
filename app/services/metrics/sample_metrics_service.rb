# frozen_string_literal: true

module Metrics
  class SampleMetricsService
    DIRECTORY = "sample_metrics"

    attr_reader :identifier, :range_minutes

    def initialize(identifier, range_start:, range_end:)
      @identifier = identifier
      @range_minutes = convert_range_minutes(range_start, range_end)
    end

    def query
      return unless identifier && File.exist?(file_location)

      query_interval
    end

    private

    def file_location
      sanitized_string = identifier.gsub(/[^0-9A-Za-z_]/, '')
      File.join(Rails.root, DIRECTORY, "#{sanitized_string}.yml")
    end

    def query_interval
      result = YAML.load_file(File.expand_path(file_location, __dir__))
      result[range_minutes]
    end

    def convert_range_minutes(range_start, range_end)
      ((range_end.to_time - range_start.to_time) / 1.minute).to_i
    end
  end
end
