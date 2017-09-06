module Gitlab
  module Metrics
    # Class for storing metrics information of a single transaction.
    class Transaction
      CONTROLLER_KEY = 'action_controller.instance'.freeze
      ENDPOINT_KEY = 'api.endpoint'.freeze

      CONTENT_TYPES = {
        'text/html' => :html,
        'text/plain' => :txt,
        'application/json' => :json,
        'text/js' => :js,
        'application/atom+xml' => :atom,
        'image/png' => :png,
        'image/jpeg' => :jpeg,
        'image/gif' => :gif,
        'image/svg+xml' => :svg
      }.freeze

      THREAD_KEY = :_gitlab_metrics_transaction

      # The series to store events (e.g. Git pushes) in.
      EVENT_SERIES = 'events'.freeze

      attr_reader :tags, :values, :method, :metrics

      def self.current
        Thread.current[THREAD_KEY]
      end

      # action - A String describing the action performed, usually the class
      #          plus method name.
      def initialize(env)
        @metrics = []
        @methods = {}

        @started_at = nil
        @finished_at = nil

        @values = Hash.new(0)
        @tags = {}
        @env = env

        @memory_before = 0
        @memory_after = 0
      end

      def duration
        @finished_at ? (@finished_at - @started_at) : 0.0
      end

      def allocated_memory
        @memory_after - @memory_before
      end

      def action
        @action ||= if @env[CONTROLLER_KEY]
                      action_from_controller(@env) || ''
                    elsif @env[ENDPOINT_KEY]
                      action_from_endpoint(@env) || ''
                    end
      end

      def run
        Thread.current[THREAD_KEY] = self

        @memory_before = System.memory_usage
        @started_at = System.monotonic_time

        yield
      ensure
        @memory_after = System.memory_usage
        @finished_at = System.monotonic_time

        Transaction.metric_transaction_duration_seconds.observe({ action: action }, duration * 1000)
        Transaction.metric_transaction_allocated_memory_bytes.observe({ action: action }, allocated_memory * 1024.0)

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
        self.class.metric_event_counter(event_name, tags).increment(tags.merge({ action: action }))
        @metrics << Metric.new(EVENT_SERIES, { count: 1 }, tags, :event)
      end

      # Returns a MethodCall object for the given name.
      def method_call_for(name)
        unless method = @methods[name]
          @methods[name] = method = MethodCall.new(name, action)
        end

        method
      end

      def increment(name, value, use_prometheus = true)
        self.class.metric_transaction_counter(name).increment({ action: action }, value) if use_prometheus
        @values[name] += value
      end

      def set(name, value, use_prometheus = true)
        self.class.metric_transaction_gauge(name).set({ action: action }, value) if use_prometheus
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

          hash[:tags][:action] ||= action if action && !metric.event?

          hash
        end

        Metrics.submit_metrics(submit_hashes)
      end

      private

      def self.metric_transaction_duration_seconds
        @metric_transaction_duration_seconds ||= Gitlab::Metrics.histogram(
          :gitlab_transaction_duration_seconds,
          'Transaction duration',
          { action: nil },
          [0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.500, 2.0, 10.0]
        )
      end

      def self.metric_transaction_allocated_memory_bytes
        @metric_transaction_allocated_memory_bytes ||= Gitlab::Metrics.histogram(
          :gitlab_transaction_allocated_memory_bytes,
          'Transaction allocated memory bytes',
          { action: nil },
          [1000, 10000, 20000, 500000, 1000000, 2000000, 5000000, 10000000, 20000000, 100000000]
        )
      end

      def self.metric_event_counter(event_name, tags)
        @metric_event_counters ||= {}
        @metric_event_counters[event_name] ||= Gitlab::Metrics.counter(
          "gitlab_transaction_event_#{event_name}_total".to_sym,
          "Transaction event #{event_name} counter",
          tags.merge({ action: nil })
        )
      end

      def self.metric_transaction_counter(name)
        @metric_transaction_counters ||= {}
        @metric_transaction_counters[name] ||= Gitlab::Metrics.counter(
          "gitlab_transaction_#{name}_total".to_sym, "Transaction #{name} counter", action: nil
        )
      end

      def self.metric_transaction_gauge(name)
        @metric_transaction_gauges ||= {}
        @metric_transaction_gauges[name] ||= Gitlab::Metrics.gauge(
          "gitlab_transaction_#{name}".to_sym, "Transaction gauge #{name}", { action: nil }, :livesum
        )
      end

      def action_from_controller(env)
        controller = env[CONTROLLER_KEY]

        action = "#{controller.class.name}##{controller.action_name}"
        suffix = CONTENT_TYPES[controller.content_type]

        if suffix && suffix != :html
          action += ".#{suffix}"
        end

        action
      end

      def action_from_endpoint(env)
        endpoint = env[ENDPOINT_KEY]

        begin
          route = endpoint.route
        rescue
          # endpoint.route is calling env[Grape::Env::GRAPE_ROUTING_ARGS][:route_info]
          # but env[Grape::Env::GRAPE_ROUTING_ARGS] is nil in the case of a 405 response
          # so we're rescuing exceptions and bailing out
        end

        if route
          path = endpoint_paths_cache[route.request_method][route.path]
          "Grape##{route.request_method} #{path}"
        end
      end
    end
  end
end
