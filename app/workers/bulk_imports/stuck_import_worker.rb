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

      BulkImports::Entity.includes(:trackers).stale.find_each do |import| # rubocop: disable CodeReuse/ActiveRecord
        ApplicationRecord.transaction do
          import.cleanup_stale

          import.trackers.find_each do |tracker|
            tracker.cleanup_stale
          end
        end
      end
    end
  end
end
