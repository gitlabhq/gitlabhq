# frozen_string_literal: true

module Gitlab
  module Memory
    # A background thread that observes Ruby heap fragmentation and calls
    # into a handler when the Ruby heap has been fragmented for an extended
    # period of time.
    #
    # See Gitlab::Metrics::Memory for how heap fragmentation is defined.
    #
    # To decide whether a given fragmentation level is being exceeded,
    # the watchdog regularly polls the GC. Whenever a violation occurs
    # a strike is issued. If the maximum number of strikes are reached,
    # a handler is invoked to deal with the situation.
    #
    # The duration for which a process may be above a given fragmentation
    # threshold is computed as `max_strikes * sleep_time_seconds`.
    class Watchdog < Daemon
      DEFAULT_SLEEP_TIME_SECONDS = 60
      DEFAULT_HEAP_FRAG_THRESHOLD = 0.5
      DEFAULT_MAX_STRIKES = 5

      # This handler does nothing. It returns `false` to indicate to the
      # caller that the situation has not been dealt with so it will
      # receive calls repeatedly if fragmentation remains high.
      #
      # This is useful for "dress rehearsals" in production since it allows
      # us to observe how frequently the handler is invoked before taking action.
      class NullHandler
        include Singleton

        def on_high_heap_fragmentation(value)
          # NOP
          false
        end
      end

      # This handler sends SIGTERM and considers the situation handled.
      class TermProcessHandler
        def initialize(pid = $$)
          @pid = pid
        end

        def on_high_heap_fragmentation(value)
          Process.kill(:TERM, @pid)
          true
        end
      end

      # This handler invokes Puma's graceful termination handler, which takes
      # into account a configurable grace period during which a process may
      # remain unresponsive to a SIGTERM.
      class PumaHandler
        def initialize(puma_options = ::Puma.cli_config.options)
          @worker = ::Puma::Cluster::WorkerHandle.new(0, $$, 0, puma_options)
        end

        def on_high_heap_fragmentation(value)
          @worker.term
          true
        end
      end

      # max_heap_fragmentation:
      #   The degree to which the Ruby heap is allowed to be fragmented. Range [0,1].
      # max_strikes:
      #   How many times the process is allowed to be above max_heap_fragmentation before
      #   a handler is invoked.
      # sleep_time_seconds:
      #   Used to control the frequency with which the watchdog will wake up and poll the GC.
      def initialize(
        handler: NullHandler.instance,
        logger: Logger.new($stdout),
        max_heap_fragmentation: ENV['GITLAB_MEMWD_MAX_HEAP_FRAG']&.to_f || DEFAULT_HEAP_FRAG_THRESHOLD,
        max_strikes: ENV['GITLAB_MEMWD_MAX_STRIKES']&.to_i || DEFAULT_MAX_STRIKES,
        sleep_time_seconds: ENV['GITLAB_MEMWD_SLEEP_TIME_SEC']&.to_i || DEFAULT_SLEEP_TIME_SECONDS,
        **options)
        super(**options)

        @handler = handler
        @logger = logger
        @max_heap_fragmentation = max_heap_fragmentation
        @sleep_time_seconds = sleep_time_seconds
        @max_strikes = max_strikes

        @alive = true
        @strikes = 0

        init_prometheus_metrics(max_heap_fragmentation)
      end

      attr_reader :strikes, :max_heap_fragmentation, :max_strikes, :sleep_time_seconds

      def run_thread
        @logger.info(log_labels.merge(message: 'started'))

        while @alive
          sleep(@sleep_time_seconds)

          monitor_heap_fragmentation if Feature.enabled?(:gitlab_memory_watchdog, type: :ops)
        end

        @logger.info(log_labels.merge(message: 'stopped'))
      end

      private

      def monitor_heap_fragmentation
        heap_fragmentation = Gitlab::Metrics::Memory.gc_heap_fragmentation

        if heap_fragmentation > @max_heap_fragmentation
          @strikes += 1
          @heap_frag_violations.increment
        else
          @strikes = 0
        end

        if @strikes > @max_strikes
          # If the handler returns true, it means the event is handled and we can shut down.
          @alive = !handle_heap_fragmentation_limit_exceeded(heap_fragmentation)
          @strikes = 0
        end
      end

      def handle_heap_fragmentation_limit_exceeded(value)
        @logger.warn(
          log_labels.merge(
            message: 'heap fragmentation limit exceeded',
            memwd_cur_heap_frag: value
          ))
        @heap_frag_violations_handled.increment

        handler.on_high_heap_fragmentation(value)
      end

      def handler
        # This allows us to keep the watchdog running but turn it into "friendly mode" where
        # all that happens is we collect logs and Prometheus events for fragmentation violations.
        return NullHandler.instance unless Feature.enabled?(:enforce_memory_watchdog, type: :ops)

        @handler
      end

      def stop_working
        @alive = false
      end

      def log_labels
        {
          pid: $$,
          worker_id: worker_id,
          memwd_handler_class: handler.class.name,
          memwd_sleep_time_s: @sleep_time_seconds,
          memwd_max_heap_frag: @max_heap_fragmentation,
          memwd_max_strikes: @max_strikes,
          memwd_cur_strikes: @strikes,
          memwd_rss_bytes: process_rss_bytes
        }
      end

      def worker_id
        ::Prometheus::PidProvider.worker_id
      end

      def process_rss_bytes
        Gitlab::Metrics::System.memory_usage_rss
      end

      def init_prometheus_metrics(max_heap_fragmentation)
        @heap_frag_limit = Gitlab::Metrics.gauge(
          :gitlab_memwd_heap_frag_limit,
          'The configured limit for how fragmented the Ruby heap is allowed to be'
        )
        @heap_frag_limit.set({}, max_heap_fragmentation)

        default_labels = { pid: worker_id }
        @heap_frag_violations = Gitlab::Metrics.counter(
          :gitlab_memwd_heap_frag_violations_total,
          'Total number of times heap fragmentation in a Ruby process exceeded its allowed maximum',
          default_labels
        )
        @heap_frag_violations_handled = Gitlab::Metrics.counter(
          :gitlab_memwd_heap_frag_violations_handled_total,
          'Total number of times heap fragmentation violations in a Ruby process were handled',
          default_labels
        )
      end
    end
  end
end
