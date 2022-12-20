# frozen_string_literal: true

return unless Gitlab::Utils.to_boolean(ENV['GITLAB_DIAGNOSTIC_REPORTS_ENABLED'])

return unless Gitlab::Runtime.puma?

Gitlab::Cluster::LifecycleEvents.on_worker_start do
  Gitlab::Memory::ReportsDaemon.instance.start
end

Gitlab::Cluster::LifecycleEvents.on_worker_stop do
  Gitlab::Memory::Reporter.new.run_report(
    Gitlab::Memory::Reports::HeapDump.new
  )
end
