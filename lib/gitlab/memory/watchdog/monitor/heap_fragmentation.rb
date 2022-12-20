# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      module Monitor
        # A monitor that observes Ruby heap fragmentation.
        # See Gitlab::Metrics::Memory for how heap fragmentation is defined.
        class HeapFragmentation
          attr_reader :max_heap_fragmentation

          # max_heap_fragmentation:
          #   The degree to which the Ruby heap is allowed to be fragmented. Range [0,1].
          def initialize(max_heap_fragmentation:)
            @max_heap_fragmentation = max_heap_fragmentation
            init_frag_limit_metrics
          end

          def call
            heap_fragmentation = Gitlab::Metrics::Memory.gc_heap_fragmentation

            return { threshold_violated: false, payload: {} } if heap_fragmentation <= max_heap_fragmentation

            { threshold_violated: true, payload: payload(heap_fragmentation) }
          end

          private

          def payload(heap_fragmentation)
            {
              message: 'heap fragmentation limit exceeded',
              memwd_cur_heap_frag: heap_fragmentation,
              memwd_max_heap_frag: max_heap_fragmentation
            }
          end

          def init_frag_limit_metrics
            heap_frag_limit = Gitlab::Metrics.gauge(
              :gitlab_memwd_heap_frag_limit,
              'The configured limit for how fragmented the Ruby heap is allowed to be'
            )
            heap_frag_limit.set({}, max_heap_fragmentation)
          end
        end
      end
    end
  end
end
