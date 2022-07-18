# frozen_string_literal: true

return unless Gitlab::Runtime.application?
return unless Gitlab::Utils.to_boolean(ENV['GITLAB_MEMORY_WATCHDOG_ENABLED'])

Gitlab::Cluster::LifecycleEvents.on_worker_start do
  handler =
    if Gitlab::Runtime.puma?
      Gitlab::Memory::Watchdog::PumaHandler.new
    elsif Gitlab::Runtime.sidekiq?
      Gitlab::Memory::Watchdog::TermProcessHandler.new
    else
      Gitlab::Memory::Watchdog::NullHandler.instance
    end

  Gitlab::Memory::Watchdog.new(
    handler: handler, logger: Gitlab::AppLogger
  ).start
end
