# frozen_string_literal: true

module Metrics
  class SampleMetricsService
    DIRECTORY = "sample_metrics"

    attr_reader :identifier

    def initialize(identifier)
      @identifier = identifier
    end

    def query
      return unless identifier && File.exist?(file_location)

      YAML.load_file(File.expand_path(file_location, __dir__))
    end

    private

    def file_location
      sanitized_string = identifier.gsub(/[^0-9A-Za-z_]/, '')
      File.join(Rails.root, DIRECTORY, "#{sanitized_string}.yml")
    end
  end
end
