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
        logger.error(message: 'BulkImport stale', bulk_import_id: import.id)
        import.cleanup_stale
      end

      BulkImports::Entity.includes(:trackers).stale.find_each do |entity| # rubocop: disable CodeReuse/ActiveRecord
        ApplicationRecord.transaction do
          logger.with_entity(entity).error(
            message: 'BulkImports::Entity stale'
          )

          entity.cleanup_stale

          entity.trackers.find_each do |tracker|
            tracker.cleanup_stale
          end
        end
      end
    end

    def logger
      @logger ||= Logger.build
    end
  end
end
