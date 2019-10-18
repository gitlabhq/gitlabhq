# frozen_string_literal: true

class ImportExportProjectCleanupWorker
  include ApplicationWorker
  include CronjobQueue

  feature_category :importers

  def perform
    ImportExportCleanUpService.new.execute
  end
end
