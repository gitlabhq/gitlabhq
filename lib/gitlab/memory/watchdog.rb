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
    class Watchdog
      DEFAULT_SLEEP_TIME_SECONDS = 60 * 5
      DEFAULT_MAX_HEAP_FRAG = 0.5
      DEFAULT_MAX_MEM_GROWTH = 3.0
      DEFAULT_MAX_STRIKES = 5

      # This handler does nothing. It returns `false` to indicate to the
      # caller that the situation has not been dealt with so it will
      # receive calls repeatedly if fragmentation remains high.
      #
      # This is useful for "dress rehearsals" in production since it allows
      # us to observe how frequently the handler is invoked before taking action.
      class NullHandler
        include Singleton

        def call
          # NOP
          false
        end
      end

      # This handler sends SIGTERM and considers the situation handled.
      class TermProcessHandler
        def initialize(pid = $$)
          @pid = pid
        end

        def call
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

        def call
          @worker.term
          true
        end
      end

      # max_heap_fragmentation:
      #   The degree to which the Ruby heap is allowed to be fragmented. Range [0,1].
      # max_mem_growth:
      #   A multiplier for how much excess private memory a worker can map compared to a reference process
      #   (itself or the primary in a pre-fork server.)
      # max_strikes:
      #   How many times the process is allowed to be above max_heap_fragmentation before
      #   a handler is invoked.
      # sleep_time_seconds:
      #   Used to control the frequency with which the watchdog will wake up and poll the GC.
      def initialize(
        handler: NullHandler.instance,
        logger: Logger.new($stdout),
        max_heap_fragmentation: ENV['GITLAB_MEMWD_MAX_HEAP_FRAG']&.to_f || DEFAULT_MAX_HEAP_FRAG,
        max_mem_growth: ENV['GITLAB_MEMWD_MAX_MEM_GROWTH']&.to_f || DEFAULT_MAX_MEM_GROWTH,
        max_strikes: ENV['GITLAB_MEMWD_MAX_STRIKES']&.to_i || DEFAULT_MAX_STRIKES,
        sleep_time_seconds: ENV['GITLAB_MEMWD_SLEEP_TIME_SEC']&.to_i || DEFAULT_SLEEP_TIME_SECONDS,
        **options)
        super(**options)

        @handler = handler
        @logger = logger
        @sleep_time_seconds = sleep_time_seconds
        @max_strikes = max_strikes
        @stats = {
          heap_frag: {
            max: max_heap_fragmentation,
            strikes: 0
          },
          mem_growth: {
            max: max_mem_growth,
            strikes: 0
          }
        }

        @alive = true

        init_prometheus_metrics(max_heap_fragmentation)
      end

      attr_reader :max_strikes, :sleep_time_seconds

      def max_heap_fragmentation
        @stats[:heap_frag][:max]
      end

      def max_mem_growth
        @stats[:mem_growth][:max]
      end

      def strikes(stat)
        @stats[stat][:strikes]
      end

      def call
        @logger.info(log_labels.merge(message: 'started'))

        while @alive
          sleep(@sleep_time_seconds)

          next unless Feature.enabled?(:gitlab_memory_watchdog, type: :ops)

          monitor_heap_fragmentation
          monitor_memory_growth
        end

        @logger.info(log_labels.merge(message: 'stopped'))
      end

      def stop
        @alive = false
      end

      private

      def monitor_memory_condition(stat_key)
        return unless @alive

        stat = @stats[stat_key]

        ok, labels = yield(stat)

        if ok
          stat[:strikes] = 0
        else
          stat[:strikes] += 1
          @counter_violations.increment(reason: stat_key.to_s)
        end

        if stat[:strikes] > @max_strikes
          @alive = !memory_limit_exceeded_callback(stat_key, labels)
          stat[:strikes] = 0
        end
      end

      def monitor_heap_fragmentation
        monitor_memory_condition(:heap_frag) do |stat|
          heap_fragmentation = Gitlab::Metrics::Memory.gc_heap_fragmentation
          [
            heap_fragmentation <= stat[:max],
            {
              message: 'heap fragmentation limit exceeded',
              memwd_cur_heap_frag: heap_fragmentation,
              memwd_max_heap_frag: stat[:max]
            }
          ]
        end
      end

      def monitor_memory_growth
        monitor_memory_condition(:mem_growth) do |stat|
          worker_uss = Gitlab::Metrics::System.memory_usage_uss_pss[:uss]
          reference_uss = reference_mem[:uss]
          memory_limit = stat[:max] * reference_uss
          [
            worker_uss <= memory_limit,
            {
              message: 'memory limit exceeded',
              memwd_uss_bytes: worker_uss,
              memwd_ref_uss_bytes: reference_uss,
              memwd_max_uss_bytes: memory_limit
            }
          ]
        end
      end

      # On pre-fork systems this would be the primary process memory from which workers fork.
      # Otherwise it is the current process' memory.
      #
      # We initialize this lazily because in the initializer the application may not have
      # finished booting yet, which would yield an incorrect baseline.
      def reference_mem
        @reference_mem ||= Gitlab::Metrics::System.memory_usage_uss_pss(pid: Gitlab::Cluster::PRIMARY_PID)
      end

      def memory_limit_exceeded_callback(stat_key, handler_labels)
        all_labels = log_labels.merge(handler_labels)
          .merge(memwd_cur_strikes: strikes(stat_key))
        @logger.warn(all_labels)
        @counter_violations_handled.increment(reason: stat_key.to_s)

        handler.call
      end

      def handler
        # This allows us to keep the watchdog running but turn it into "friendly mode" where
        # all that happens is we collect logs and Prometheus events for fragmentation violations.
        return NullHandler.instance unless Feature.enabled?(:enforce_memory_watchdog, type: :ops)

        @handler
      end

      def log_labels
        {
          pid: $$,
          worker_id: worker_id,
          memwd_handler_class: handler.class.name,
          memwd_sleep_time_s: @sleep_time_seconds,
          memwd_max_strikes: @max_strikes,
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
        @counter_violations = Gitlab::Metrics.counter(
          :gitlab_memwd_violations_total,
          'Total number of times a Ruby process violated a memory threshold',
          default_labels
        )
        @counter_violations_handled = Gitlab::Metrics.counter(
          :gitlab_memwd_violations_handled_total,
          'Total number of times Ruby process memory violations were handled',
          default_labels
        )
      end
    end
  end
end
