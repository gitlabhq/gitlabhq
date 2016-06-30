module Gitlab
  module Metrics
    # Class for storing metrics information of a single transaction.
    class Transaction
      THREAD_KEY = :_gitlab_metrics_transaction

      attr_reader :tags, :values, :methods

      attr_accessor :action

      def self.current
        Thread.current[THREAD_KEY]
      end

      # action - A String describing the action performed, usually the class
      #          plus method name.
      def initialize(action = nil)
        @metrics = []
        @methods = {}

        @started_at  = nil
        @finished_at = nil

        @values = Hash.new(0)
        @tags   = {}
        @action = action

        @memory_before = 0
        @memory_after  = 0
      end

      def duration
        @finished_at ? (@finished_at - @started_at) : 0.0
      end

      def allocated_memory
        @memory_after - @memory_before
      end

      def run
        Thread.current[THREAD_KEY] = self

        @memory_before = System.memory_usage
        @started_at    = System.monotonic_time

        yield
      ensure
        @memory_after = System.memory_usage
        @finished_at  = System.monotonic_time

        Thread.current[THREAD_KEY] = nil
      end

      def add_metric(series, values, tags = {})
        @metrics << Metric.new("#{series_prefix}#{series}", values, tags)
      end

      # Measures the time it takes to execute a method.
      #
      # Multiple calls to the same method add up to the total runtime of the
      # method.
      #
      # name - The full name of the method to measure (e.g. `User#sign_in`).
      def measure_method(name, &block)
        unless @methods[name]
          series = "#{series_prefix}#{Instrumentation::SERIES}"

          @methods[name] = MethodCall.new(name, series)
        end

        @methods[name].measure(&block)
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
        values = { duration: duration, allocated_memory: allocated_memory }

        @values.each do |name, value|
          values[name] = value
        end

        add_metric('transactions', values, @tags)
      end

      def submit
        submit = @metrics.dup

        @methods.each do |name, method|
          submit << method.to_metric if method.above_threshold?
        end

        submit_hashes = submit.map do |metric|
          hash = metric.to_hash

          hash[:tags][:action] ||= @action if @action

          hash
        end

        Metrics.submit_metrics(submit_hashes)
      end

      def sidekiq?
        Sidekiq.server?
      end

      def series_prefix
        sidekiq? ? 'sidekiq_' : 'rails_'
      end
    end
  end
end
