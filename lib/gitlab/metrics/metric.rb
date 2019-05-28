# frozen_string_literal: true

module Gitlab
  module Metrics
    # Class for storing details of a single metric (label, value, etc).
    class Metric
      JITTER_RANGE = (0.000001..0.001).freeze

      attr_reader :series, :values, :tags, :type

      # series - The name of the series (as a String) to store the metric in.
      # values - A Hash containing the values to store.
      # tags   - A Hash containing extra tags to add to the metrics.
      def initialize(series, values, tags = {}, type = :metric)
        @values = values
        @series = series
        @tags   = tags
        @type   = type
      end

      def event?
        type == :event
      end

      # Returns a Hash in a format that can be directly written to InfluxDB.
      def to_hash
        # InfluxDB overwrites an existing point if a new point has the same
        # series, tag set, and timestamp. In a highly concurrent environment
        # this means that using the number of seconds since the Unix epoch is
        # inevitably going to collide with another timestamp. For example, two
        # Rails requests processed by different processes may end up generating
        # metrics using the _exact_ same timestamp (in seconds).
        #
        # Due to the way InfluxDB is set up there's no solution to this problem,
        # all we can do is lower the amount of collisions. We do this by using
        # System.real_time which returns the nanoseconds as a Float providing
        # greater accuracy. We then add a small random value that is large
        # enough to distinguish most timestamps but small enough to not alter
        # the timestamp significantly.
        #
        # See https://gitlab.com/gitlab-com/operations/issues/175 for more
        # information.
        time = System.real_time(:nanosecond) + rand(JITTER_RANGE)

        {
          series:    @series,
          tags:      @tags,
          values:    @values,
          timestamp: time.to_i
        }
      end
    end
  end
end
