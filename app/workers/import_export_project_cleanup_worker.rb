class ImportExportProjectCleanupWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    ImportExportCleanUpService.new.execute
  end
end
