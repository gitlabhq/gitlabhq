# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      module Monitor
        class RssMemoryLimit
          attr_reader :memory_limit_bytes

          def initialize(memory_limit_bytes:)
            @memory_limit_bytes = memory_limit_bytes
            init_memory_limit_metrics
          end

          def call
            worker_rss_bytes = Gitlab::Metrics::System.memory_usage_rss[:total]

            return { threshold_violated: false, payload: {} } if worker_rss_bytes <= memory_limit_bytes

            { threshold_violated: true, payload: payload(worker_rss_bytes, memory_limit_bytes) }
          end

          private

          def payload(worker_rss_bytes, memory_limit_bytes)
            {
              message: 'rss memory limit exceeded',
              memwd_rss_bytes: worker_rss_bytes,
              memwd_max_rss_bytes: memory_limit_bytes
            }
          end

          def init_memory_limit_metrics
            rss_memory_limit = Gitlab::Metrics.gauge(
              :gitlab_memwd_max_memory_limit,
              'The configured fixed limit for rss memory'
            )
            rss_memory_limit.set({}, memory_limit_bytes)
          end
        end
      end
    end
  end
end
