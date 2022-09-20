# frozen_string_literal: true

return unless Gitlab::Utils.to_boolean(ENV['GITLAB_DIAGNOSTIC_REPORTS_ENABLED'])

return unless Gitlab::Runtime.puma?

Gitlab::Cluster::LifecycleEvents.on_worker_start do
  Gitlab::Memory::ReportsDaemon.instance.start

  # Avoid concurrent uploads, so thread out from a single worker.
  # We want only one uploader thread running for the Puma cluster.
  # We do not spawn a thread from the `master`, to keep its state pristine.
  # This should have a minimal impact on the given worker.
  if ::Prometheus::PidProvider.worker_id == 'puma_0'
    reports_watcher = Gitlab::Memory::UploadAndCleanupReports.new
    Gitlab::BackgroundTask.new(reports_watcher).start
  end
end
