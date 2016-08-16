module Gitlab
  module Metrics
    # Class for storing metrics information of a single transaction.
    class Transaction
      THREAD_KEY = :_gitlab_metrics_transaction

      # The series to store events (e.g. Git pushes) in.
      EVENT_SERIES = 'events'

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
        @metrics << Metric.new(EVENT_SERIES,
                               { count: 1 },
                               { event: event_name }.merge(tags),
                               :event)
      end

      # Returns a MethodCall object for the given name.
      def method_call_for(name)
        unless method = @methods[name]
          @methods[name] = method = MethodCall.new(name, Instrumentation.series)
        end

        method
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

          hash[:tags][:action] ||= @action if @action && !metric.event?

          hash
        end

        Metrics.submit_metrics(submit_hashes)
      end
    end
  end
end
