class ImportExportProjectCleanupWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    ImportExportCleanUpService.new.execute
  end
end
