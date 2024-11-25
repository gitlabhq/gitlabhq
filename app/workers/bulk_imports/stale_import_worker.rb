# frozen_string_literal: true

module BulkImports
  class StaleImportWorker
    include ApplicationWorker

    # This worker does not schedule other workers that require context.
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    idempotent!
    data_consistency :sticky

    feature_category :importers

    # Using Keyset pagination for scopes that involve timestamp indexes
    def perform
      Gitlab::Pagination::Keyset::Iterator.new(scope: bulk_import_scope).each_batch do |imports|
        imports.each do |import|
          logger.error(message: 'BulkImport stale', bulk_import_id: import.id)
          import.cleanup_stale
        end
      end

      Gitlab::Pagination::Keyset::Iterator.new(scope: entity_scope).each_batch do |entities|
        entities.each do |entity|
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
    end

    def logger
      @logger ||= Logger.build
    end

    def bulk_import_scope
      BulkImport.stale.order_by_updated_at_and_id(:asc)
    end

    def entity_scope
      BulkImports::Entity.with_trackers.stale.order_by_updated_at_and_id(:asc)
    end
  end
end
