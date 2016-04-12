module Gitlab
  module Metrics
    # Class for storing details of a single metric (label, value, etc).
    class Metric
      JITTER_RANGE = 0.000001..0.001

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
        # InfluxDB overwrites an existing point if a new point has the same
        # series, tag set, and timestamp. In a highly concurrent environment
        # this means that using the number of seconds since the Unix epoch is
        # inevitably going to collide with another timestamp. For example, two
        # Rails requests processed by different processes may end up generating
        # metrics using the _exact_ same timestamp (in seconds).
        #
        # Due to the way InfluxDB is set up there's no solution to this problem,
        # all we can do is lower the amount of collisions. We do this by using
        # Time#to_f which returns the seconds as a Float providing greater
        # accuracy. We then add a small random value that is large enough to
        # distinguish most timestamps but small enough to not alter the amount
        # of seconds.
        #
        # See https://gitlab.com/gitlab-com/operations/issues/175 for more
        # information.
        time = @created_at.to_f + rand(JITTER_RANGE)

        {
          series:    @series,
          tags:      @tags,
          values:    @values,
          timestamp: (time * 1_000_000_000).to_i
        }
      end
    end
  end
end
