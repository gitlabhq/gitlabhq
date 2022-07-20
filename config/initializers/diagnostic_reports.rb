# frozen_string_literal: true

return unless Gitlab::Utils.to_boolean(ENV['GITLAB_DIAGNOSTIC_REPORTS_ENABLED'])

# Any actions beyond this check should only execute outside of tests,
# when running in application context (i.e. not in the Rails console or rspec)
return unless Gitlab::Runtime.application?

Gitlab::Cluster::LifecycleEvents.on_worker_start do
  Gitlab::Memory::ReportsDaemon.instance.start
end
