module Gitlab
  module Metrics
    # Class for storing metrics information of a single transaction.
    class Transaction
      THREAD_KEY = :_gitlab_metrics_transaction

      # The series to store events (e.g. Git pushes) in.
      EVENT_SERIES = 'events'.freeze

      attr_reader :tags, :values, :method, :metrics

      attr_accessor :action

      def self.current
        Thread.current[THREAD_KEY]
      end

      # action - A String describing the action performed, usually the class
      #          plus method name.
      def initialize(action = nil)
        @metrics = []
        @methods = {}

        @started_at = nil
        @finished_at = nil

        @values = Hash.new(0)
        @tags = {}
        @action = action

        @memory_before = 0
        @memory_after = 0
      end

      def duration
        @finished_at ? (@finished_at - @started_at) : 0.0
      end

      def allocated_memory
        @memory_after - @memory_before
      end

      def self.metric_transaction_duration_milliseconds
        @metrics_transaction_duration_milliseconds ||= Gitlab::Metrics.histogram(
          :gitlab_transaction_duration_milliseconds,
          'Transaction duration milliseconds',
          {},
          [1, 2, 5, 10, 20, 50, 100, 500, 10000]
        )
      end

      def self.metric_transaction_allocated_memory_megabytes
        @metric_transaction_allocated_memory_megabytes ||= Gitlab::Metrics.histogram(
          :gitlab_transaction_allocated_memory_megabytes,
          'Transaction allocated memory bytes',
          {},
          [1, 2, 5, 10, 20, 100]
        )
      end

      def run
        Thread.current[THREAD_KEY] = self

        @memory_before = System.memory_usage
        @started_at = System.monotonic_time

        yield
      ensure
        @memory_after = System.memory_usage
        @finished_at = System.monotonic_time

        Transaction.metric_transaction_duration_milliseconds.observe({}, duration)
        Transaction.metric_transaction_allocated_memory_megabytes.observe({}, allocated_memory)

        Thread.current[THREAD_KEY] = nil
      end

      def add_metric(series, values, tags = {})
        @metrics << Metric.new("#{Metrics.series_prefix}#{series}", values, tags)
      end

      # Tracks a business level event
      #
      # Business level events including events such as Git pushes, Emails being
      # sent, etc.
      #
      # event_name - The name of the event (e.g. "git_push").
      # tags - A set of tags to attach to the event.
      def add_event(event_name, tags = {})
        Gitlab::Metrics.counter("gitlab_transaction_event_#{event_name}_total".to_sym, "Transaction event #{event_name}", tags).increment({})
        @metrics << Metric.new(EVENT_SERIES, { count: 1 }, tags, :event)
      end

      # Returns a MethodCall object for the given name.
      def method_call_for(name)
        unless method = @methods[name]
          @methods[name] = method = MethodCall.new(name)
        end

        method
      end

      def increment(name, value)
        Gitlab::Metrics.counter("gitlab_transaction_#{name}_total".to_sym, "Transaction counter #{name}", {}).increment({}, value)
        @values[name] += value
      end

      def set(name, value)
        Gitlab::Metrics.gauge("gitlab_transaction_#{name}".to_sym, "Transaction gauge #{name}", {}, :livesum).set({}, value)
        @values[name] = value
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

          hash[:tags][:action] ||= @action if @action && !metric.event?

          hash
        end

        Metrics.submit_metrics(submit_hashes)
      end
    end
  end
end
