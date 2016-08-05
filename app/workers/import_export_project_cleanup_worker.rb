class ImportExportProjectCleanupWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform
    ImportExportCleanUpService.new.execute
  end
end
