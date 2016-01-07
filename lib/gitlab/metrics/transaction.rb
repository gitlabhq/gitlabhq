module Gitlab
  module Metrics
    # Class for storing metrics information of a single transaction.
    class Transaction
      THREAD_KEY = :_gitlab_metrics_transaction

      attr_reader :tags, :values

      def self.current
        Thread.current[THREAD_KEY]
      end

      def initialize
        @metrics = []

        @started_at  = nil
        @finished_at = nil

        @values = Hash.new(0)
        @tags   = {}
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
        prefix = sidekiq? ? 'sidekiq_' : 'rails_'

        @metrics << Metric.new("#{prefix}#{series}", values, tags)
      end

      def increment(name, value)
        @values[name] += value
      end

      def set(name, value)
        @values[name] = value
      end

      def add_tag(key, value)
        @tags[key] = value
      end

      def finish
        track_self
        submit
      end

      def track_self
        values = { duration: duration }

        @values.each do |name, value|
          values[name] = value
        end

        add_metric('transactions', values, @tags)
      end

      def submit
        Metrics.submit_metrics(@metrics.map(&:to_hash))
      end

      def sidekiq?
        Sidekiq.server?
      end
    end
  end
end
