# frozen_string_literal: true

class ImportExportProjectCleanupWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :importers

  def perform
    ImportExportCleanUpService.new.execute
  end
end
