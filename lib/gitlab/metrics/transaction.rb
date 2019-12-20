# frozen_string_literal: true

module Gitlab
  module Metrics
    # Class for storing metrics information of a single transaction.
    class Transaction
      include Gitlab::Metrics::Methods

      # base labels shared among all transactions
      BASE_LABELS = { controller: nil, action: nil }.freeze
      # labels that potentially contain sensitive information and will be filtered
      FILTERED_LABELS = [:branch, :path].freeze

      THREAD_KEY = :_gitlab_metrics_transaction

      # The series to store events (e.g. Git pushes) in.
      EVENT_SERIES = 'events'

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

      def thread_cpu_duration
        System.thread_cpu_duration(@thread_cputime_start)
      end

      def allocated_memory
        @memory_after - @memory_before
      end

      def run
        Thread.current[THREAD_KEY] = self

        @memory_before = System.memory_usage
        @started_at = System.monotonic_time
        @thread_cputime_start = System.thread_cpu_time

        yield
      ensure
        @memory_after = System.memory_usage
        @finished_at = System.monotonic_time

        self.class.gitlab_transaction_cputime_seconds.observe(labels, thread_cpu_duration)
        self.class.gitlab_transaction_duration_seconds.observe(labels, duration)
        self.class.gitlab_transaction_allocated_memory_bytes.observe(labels, allocated_memory * 1024.0)

        Thread.current[THREAD_KEY] = nil
      end

      def add_metric(series, values, tags = {})
        @metrics << Metric.new("#{::Gitlab::Metrics.series_prefix}#{series}", values, filter_tags(tags))
      end

      # Tracks a business level event
      #
      # Business level events including events such as Git pushes, Emails being
      # sent, etc.
      #
      # event_name - The name of the event (e.g. "git_push").
      # tags - A set of tags to attach to the event.
      def add_event(event_name, tags = {})
        filtered_tags = filter_tags(tags)
        self.class.transaction_metric(event_name, :counter, prefix: 'event_', tags: filtered_tags).increment(filtered_tags.merge(labels))
        @metrics << Metric.new(EVENT_SERIES, { count: 1 }, filtered_tags.merge(event: event_name), :event)
      end

      # Returns a MethodCall object for the given name.
      def method_call_for(name, module_name, method_name)
        unless method = @methods[name]
          @methods[name] = method = MethodCall.new(name, module_name, method_name, self)
        end

        method
      end

      def increment(name, value, use_prometheus = true)
        self.class.transaction_metric(name, :counter).increment(labels, value) if use_prometheus
        @values[name] += value
      end

      def set(name, value, use_prometheus = true)
        self.class.transaction_metric(name, :gauge).set(labels, value) if use_prometheus
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

        ::Gitlab::Metrics.submit_metrics(submit_hashes)
      end

      def labels
        BASE_LABELS
      end

      # returns string describing the action performed, usually the class plus method name.
      def action
        "#{labels[:controller]}##{labels[:action]}" if labels && !labels.empty?
      end

      define_histogram :gitlab_transaction_cputime_seconds do
        docstring 'Transaction thread cputime'
        base_labels BASE_LABELS
        buckets [0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
      end

      define_histogram :gitlab_transaction_duration_seconds do
        docstring 'Transaction duration'
        base_labels BASE_LABELS
        buckets [0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
      end

      define_histogram :gitlab_transaction_allocated_memory_bytes do
        docstring 'Transaction allocated memory bytes'
        base_labels BASE_LABELS
        buckets [100, 1000, 10000, 100000, 1000000, 10000000]
      end

      def self.transaction_metric(name, type, prefix: nil, tags: {})
        metric_name = "gitlab_transaction_#{prefix}#{name}_total".to_sym
        fetch_metric(type, metric_name) do
          docstring "Transaction #{prefix}#{name} #{type}"
          base_labels tags.merge(BASE_LABELS)

          if type == :gauge
            multiprocess_mode :livesum
          end
        end
      end

      private

      def filter_tags(tags)
        tags.without(*FILTERED_LABELS)
      end
    end
  end
end
