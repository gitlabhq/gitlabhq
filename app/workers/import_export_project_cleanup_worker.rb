# frozen_string_literal: true

class ImportExportProjectCleanupWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :importers

  def perform
    ImportExportCleanUpService.new.execute
  end
end
