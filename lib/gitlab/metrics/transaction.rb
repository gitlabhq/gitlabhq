module Gitlab
  module Metrics
    # Class for storing metrics information of a single transaction.
    class Transaction
      THREAD_KEY = :_gitlab_metrics_transaction

      SERIES = 'transactions'

      attr_reader :uuid, :tags

      def self.current
        Thread.current[THREAD_KEY]
      end

      # name - The name of this transaction as a String.
      def initialize
        @metrics = []
        @uuid    = SecureRandom.uuid

        @started_at  = nil
        @finished_at = nil

        @tags = {}
      end

      def duration
        @finished_at ? (@finished_at - @started_at) * 1000.0 : 0.0
      end

      def run
        Thread.current[THREAD_KEY] = self

        @started_at = Time.now

        yield
      ensure
        @finished_at = Time.now

        Thread.current[THREAD_KEY] = nil
      end

      def add_metric(series, values, tags = {})
        tags = tags.merge(transaction_id: @uuid)

        @metrics << Metric.new(series, values, tags)
      end

      def add_tag(key, value)
        @tags[key] = value
      end

      def finish
        track_self
        submit
      end

      def track_self
        add_metric(SERIES, { duration: duration }, @tags)
      end

      def submit
        Metrics.submit_metrics(@metrics.map(&:to_hash))
      end
    end
  end
end
