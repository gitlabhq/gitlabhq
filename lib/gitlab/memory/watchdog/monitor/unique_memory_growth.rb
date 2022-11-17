# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      module Monitor
        class UniqueMemoryGrowth
          attr_reader :max_mem_growth

          def initialize(max_mem_growth:)
            @max_mem_growth = max_mem_growth
          end

          def call
            worker_uss = Gitlab::Metrics::System.memory_usage_uss_pss[:uss]
            reference_uss = reference_mem[:uss]
            memory_limit = max_mem_growth * reference_uss

            return { threshold_violated: false, payload: {} } if worker_uss <= memory_limit

            { threshold_violated: true, payload: payload(worker_uss, reference_uss, memory_limit) }
          end

          private

          def payload(worker_uss, reference_uss, memory_limit)
            {
              message: 'memory limit exceeded',
              memwd_uss_bytes: worker_uss,
              memwd_ref_uss_bytes: reference_uss,
              memwd_max_uss_bytes: memory_limit
            }
          end

          # On pre-fork systems this would be the primary process memory from which workers fork.
          # Otherwise it is the current process' memory.
          #
          # We initialize this lazily because in the initializer the application may not have
          # finished booting yet, which would yield an incorrect baseline.
          def reference_mem
            @reference_mem ||= Gitlab::Metrics::System.memory_usage_uss_pss(pid: Gitlab::Cluster::PRIMARY_PID)
          end
        end
      end
    end
  end
end
