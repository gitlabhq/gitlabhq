# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      class EventReporter
        include ::Gitlab::Utils::StrongMemoize

        attr_reader :logger

        def initialize(logger: Gitlab::AppLogger)
          @logger = logger
        end

        def started(labels = {})
          logger.info(message: 'started', **log_labels(labels))
        end

        def stopped(labels = {})
          logger.info(message: 'stopped', **log_labels(labels))
        end

        def threshold_violated(monitor_name)
          counter_violations.increment(reason: monitor_name)
        end

        def strikes_exceeded(monitor_name, labels = {})
          logger.warn(log_labels(labels))

          counter_violations_handled.increment(reason: monitor_name)
        end

        private

        def log_labels(extra = {})
          extra.merge(
            pid: $$,
            worker_id: worker_id,
            memwd_rss_bytes: process_rss_bytes
          )
        end

        def process_rss_bytes
          Gitlab::Metrics::System.memory_usage_rss[:total]
        end

        def worker_id
          ::Prometheus::PidProvider.worker_id
        end

        def counter_violations
          strong_memoize("counter_violations") do
            ::Gitlab::Metrics.counter(
              :gitlab_memwd_violations_total,
              'Total number of times a Ruby process violated a memory threshold',
              { pid: worker_id }
            )
          end
        end

        def counter_violations_handled
          strong_memoize("counter_violations_handled") do
            ::Gitlab::Metrics.counter(
              :gitlab_memwd_violations_handled_total,
              'Total number of times Ruby process memory violations were handled',
              { pid: worker_id }
            )
          end
        end
      end
    end
  end
end
