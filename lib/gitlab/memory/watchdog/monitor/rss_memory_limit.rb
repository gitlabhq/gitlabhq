# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      module Monitor
        class RssMemoryLimit
          attr_reader :memory_limit_bytes

          def initialize(memory_limit_bytes:)
            @memory_limit_bytes = memory_limit_bytes
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
        end
      end
    end
  end
end
