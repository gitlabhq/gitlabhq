# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      module Monitor
        class RssMemoryLimit
          attr_reader :memory_limit

          def initialize(memory_limit:)
            @memory_limit = memory_limit
          end

          def call
            worker_rss = Gitlab::Metrics::System.memory_usage_rss[:total]

            return { threshold_violated: false, payload: {} } if worker_rss <= memory_limit

            { threshold_violated: true, payload: payload(worker_rss, memory_limit) }
          end

          private

          def payload(worker_rss, memory_limit)
            {
              message: 'rss memory limit exceeded',
              memwd_rss_bytes: worker_rss,
              memwd_max_rss_bytes: memory_limit
            }
          end
        end
      end
    end
  end
end
