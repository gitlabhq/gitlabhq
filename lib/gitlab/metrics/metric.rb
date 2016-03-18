module Gitlab
  module Metrics
    # Class for storing details of a single metric (label, value, etc).
    class Metric
      attr_reader :series, :values, :tags, :created_at

      # series - The name of the series (as a String) to store the metric in.
      # values - A Hash containing the values to store.
      # tags   - A Hash containing extra tags to add to the metrics.
      def initialize(series, values, tags = {})
        @values     = values
        @series     = series
        @tags       = tags
        @created_at = Time.now.utc
      end

      # Returns a Hash in a format that can be directly written to InfluxDB.
      def to_hash
        {
          series:    @series,
          tags:      @tags,
          values:    @values,
          timestamp: @created_at.to_i * 1_000_000_000
        }
      end
    end
  end
end
