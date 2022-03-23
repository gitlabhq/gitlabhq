# frozen_string_literal: true

module BulkImports
  class StuckImportWorker
    include ApplicationWorker

    # This worker does not schedule other workers that require context.
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    idempotent!
    data_consistency :always

    feature_category :importers

    def perform
      BulkImport.stale.find_each do |import|
        import.cleanup_stale
      end
      BulkImports::Entity.stale.find_each do |import|
        import.cleanup_stale
      end
    end
  end
end
