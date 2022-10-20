# frozen_string_literal: true

return unless Gitlab::Runtime.application?
return unless Gitlab::Utils.to_boolean(ENV['GITLAB_MEMORY_WATCHDOG_ENABLED'])

Gitlab::Cluster::LifecycleEvents.on_worker_start do
  watchdog = Gitlab::Memory::Watchdog.new
  max_strikes = ENV.fetch('GITLAB_MEMWD_MAX_STRIKES', 5).to_i
  sleep_time_seconds = ENV.fetch('GITLAB_MEMWD_SLEEP_TIME_SEC', 60).to_i
  max_mem_growth = ENV.fetch('GITLAB_MEMWD_MAX_MEM_GROWTH', 3.0).to_f
  max_heap_frag = ENV.fetch('GITLAB_MEMWD_MAX_HEAP_FRAG', 0.5).to_f

  watchdog.configure do |config|
    config.handler =
      if Gitlab::Runtime.puma?
        Gitlab::Memory::Watchdog::PumaHandler.new
      elsif Gitlab::Runtime.sidekiq?
        Gitlab::Memory::Watchdog::TermProcessHandler.new
      else
        Gitlab::Memory::Watchdog::NullHandler.instance
      end

    config.logger = Gitlab::AppLogger
    config.sleep_time_seconds = sleep_time_seconds
    # config.monitor.use MonitorClass, args*, max_strikes:, kwargs**, &block
    config.monitors.use Gitlab::Memory::Watchdog::Monitor::HeapFragmentation,
      max_heap_fragmentation: max_heap_frag,
      max_strikes: max_strikes

    config.monitors.use Gitlab::Memory::Watchdog::Monitor::UniqueMemoryGrowth,
      max_mem_growth: max_mem_growth,
      max_strikes: max_strikes
  end

  Gitlab::BackgroundTask.new(watchdog).start
end
