# frozen_string_literal: true

return unless Gitlab::Runtime.application?
return unless Gitlab::Utils.to_boolean(ENV['GITLAB_MEMORY_WATCHDOG_ENABLED'], default: true)

Gitlab::Cluster::LifecycleEvents.on_worker_start do
  watchdog = Gitlab::Memory::Watchdog.new
  if Gitlab::Runtime.puma?
    watchdog.configure(&Gitlab::Memory::Watchdog::Configurator.configure_for_puma)
  elsif Gitlab::Runtime.sidekiq?
    watchdog.configure(&Gitlab::Memory::Watchdog::Configurator.configure_for_sidekiq)
  end

  Gitlab::BackgroundTask.new(watchdog).start
end
