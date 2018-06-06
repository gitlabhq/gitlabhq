class StorageCleanupCronWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    StorageCleanupService.new(Gitlab.config.lfs).execute
    StorageCleanupService.new(Gitlab.config.artifacts).execute
    StorageCleanupService.new(Gitlab.config.uploads).execute
  end
end
