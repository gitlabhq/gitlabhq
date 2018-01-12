module Gitlab
  module Metrics
    # Class for storing metrics information of a single transaction.
    class Transaction
      # base labels shared among all transactions
      BASE_LABELS = { controller: nil, action: nil }.freeze

      THREAD_KEY = :_gitlab_metrics_transaction
      METRICS_MUTEX = Mutex.new

      # The series to store events (e.g. Git pushes) in.
      EVENT_SERIES = 'events'.freeze

      attr_reader :tags, :values, :method, :metrics

      def self.current
        Thread.current[THREAD_KEY]
      end

      def initialize
        @metrics = []
        @methods = {}

        @started_at = nil
        @finished_at = nil

        @values = Hash.new(0)
        @tags = {}

        @memory_before = 0
        @memory_after = 0
      end

      def duration
        @finished_at ? (@finished_at - @started_at) : 0.0
      end

      def duration_milliseconds
        duration.in_milliseconds.to_i
      end

      def allocated_memory
        @memory_after - @memory_before
      end

      def run
        Thread.current[THREAD_KEY] = self

        @memory_before = System.memory_usage
        @started_at = System.monotonic_time

        yield
      ensure
        @memory_after = System.memory_usage
        @finished_at = System.monotonic_time

        self.class.metric_transaction_duration_seconds.observe(labels, duration)
        self.class.metric_transaction_allocated_memory_bytes.observe(labels, allocated_memory * 1024.0)

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
        self.class.metric_event_counter(event_name, tags).increment(tags.merge(labels))
        @metrics << Metric.new(EVENT_SERIES, { count: 1 }, tags.merge(event: event_name), :event)
      end

      #
      # Deprecated
      def add_event_with_values(event_name, values, tags = {})
        @metrics << Metric.new(EVENT_SERIES,
                               { count: 1 }.merge(values),
                               { event: event_name }.merge(tags),
                               :event)
      end

      # Returns a MethodCall object for the given name.
      def method_call_for(name, module_name, method_name)
        unless method = @methods[name]
          @methods[name] = method = MethodCall.new(name, module_name, method_name, self)
        end

        method
      end

      def increment(name, value, use_prometheus = true)
        self.class.metric_transaction_counter(name).increment(labels, value) if use_prometheus
        @values[name] += value
      end

      def set(name, value, use_prometheus = true)
        self.class.metric_transaction_gauge(name).set(labels, value) if use_prometheus
        @values[name] = value
      end

      def finish
        track_self
        submit
      end

      def track_self
        values = { duration: duration_milliseconds, allocated_memory: allocated_memory }

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
          hash[:tags][:action] ||= action if action && !metric.event?

          hash
        end

        Metrics.submit_metrics(submit_hashes)
      end

      def labels
        BASE_LABELS
      end

      # returns string describing the action performed, usually the class plus method name.
      def action
        "#{labels[:controller]}##{labels[:action]}" if labels && !labels.empty?
      end

      def self.metric_transaction_duration_seconds
        return @metric_transaction_duration_seconds if @metric_transaction_duration_seconds

        METRICS_MUTEX.synchronize do
          @metric_transaction_duration_seconds ||= Gitlab::Metrics.histogram(
            :gitlab_transaction_duration_seconds,
            'Transaction duration',
            BASE_LABELS,
            [0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.500, 2.0, 10.0]
          )
        end
      end

      def self.metric_transaction_allocated_memory_bytes
        return @metric_transaction_allocated_memory_bytes if @metric_transaction_allocated_memory_bytes

        METRICS_MUTEX.synchronize do
          @metric_transaction_allocated_memory_bytes ||= Gitlab::Metrics.histogram(
            :gitlab_transaction_allocated_memory_bytes,
            'Transaction allocated memory bytes',
            BASE_LABELS,
            [1000, 10000, 20000, 500000, 1000000, 2000000, 5000000, 10000000, 20000000, 100000000]
          )
        end
      end

      def self.metric_event_counter(event_name, tags)
        return @metric_event_counters[event_name] if @metric_event_counters&.has_key?(event_name)

        METRICS_MUTEX.synchronize do
          @metric_event_counters ||= {}
          @metric_event_counters[event_name] ||= Gitlab::Metrics.counter(
            "gitlab_transaction_event_#{event_name}_total".to_sym,
            "Transaction event #{event_name} counter",
            tags.merge(BASE_LABELS)
          )
        end
      end

      def self.metric_transaction_counter(name)
        return @metric_transaction_counters[name] if @metric_transaction_counters&.has_key?(name)

        METRICS_MUTEX.synchronize do
          @metric_transaction_counters ||= {}
          @metric_transaction_counters[name] ||= Gitlab::Metrics.counter(
            "gitlab_transaction_#{name}_total".to_sym, "Transaction #{name} counter", BASE_LABELS
          )
        end
      end

      def self.metric_transaction_gauge(name)
        return @metric_transaction_gauges[name] if @metric_transaction_gauges&.has_key?(name)

        METRICS_MUTEX.synchronize do
          @metric_transaction_gauges ||= {}
          @metric_transaction_gauges[name] ||= Gitlab::Metrics.gauge(
            "gitlab_transaction_#{name}".to_sym, "Transaction gauge #{name}", BASE_LABELS, :livesum
          )
        end
      end
    end
  end
end
