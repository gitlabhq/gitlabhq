# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      class Configurator
        class << self
          def configure_for_puma
            lambda do |config|
              config.logger = Gitlab::AppLogger
              config.handler = Gitlab::Memory::Watchdog::PumaHandler.new
              config.write_heap_dumps = write_heap_dumps?
              config.sleep_time_seconds = ENV.fetch('GITLAB_MEMWD_SLEEP_TIME_SEC', 60).to_i
              config.monitors(&configure_monitors_for_puma)
            end
          end

          def configure_for_sidekiq
            lambda do |config|
              config.logger = Sidekiq.logger
              config.handler = Gitlab::Memory::Watchdog::TermProcessHandler.new
              config.write_heap_dumps = write_heap_dumps?
              config.sleep_time_seconds = [
                ENV.fetch('SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL', 3).to_i, 2
              ].max
              config.monitors(&configure_monitors_for_sidekiq)
            end
          end

          private

          def write_heap_dumps?
            Gitlab::Utils.to_boolean(ENV['GITLAB_MEMWD_DUMP_HEAP'], default: false)
          end

          def configure_monitors_for_puma
            lambda do |stack|
              max_strikes = ENV.fetch('GITLAB_MEMWD_MAX_STRIKES', 5).to_i

              if Gitlab::Utils.to_boolean(ENV['DISABLE_PUMA_WORKER_KILLER'])
                max_heap_frag = ENV.fetch('GITLAB_MEMWD_MAX_HEAP_FRAG', 0.5).to_f
                max_mem_growth = ENV.fetch('GITLAB_MEMWD_MAX_MEM_GROWTH', 3.0).to_f

                # stack.push MonitorClass, args*, max_strikes:, kwargs**, &block
                stack.push Gitlab::Memory::Watchdog::Monitor::HeapFragmentation,
                           max_heap_fragmentation: max_heap_frag,
                           max_strikes: max_strikes

                stack.push Gitlab::Memory::Watchdog::Monitor::UniqueMemoryGrowth,
                           max_mem_growth: max_mem_growth,
                           max_strikes: max_strikes
              else
                memory_limit = ENV.fetch('PUMA_WORKER_MAX_MEMORY', 1200).to_i

                stack.push Gitlab::Memory::Watchdog::Monitor::RssMemoryLimit,
                           memory_limit: memory_limit.megabytes,
                           max_strikes: max_strikes
              end
            end
          end

          def configure_monitors_for_sidekiq
            # NOP - At the moment we don't run watchdog for Sidekiq
          end
        end
      end
    end
  end
end
