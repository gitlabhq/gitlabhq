# frozen_string_literal: true

module BulkImports
  class FinishBatchedRelationExportWorker
    include ApplicationWorker

    idempotent!
    data_consistency :sticky
    feature_category :importers

    REENQUEUE_DELAY = 5.seconds
    TIMEOUT = 6.hours

    def perform(export_id)
      @export = Export.find_by_id(export_id)

      return unless export
      return if export.finished? || export.failed?
      return fail_export! if export_timeout?
      return re_enqueue if export_in_progress?

      finish_export!
    end

    private

    attr_reader :export

    def fail_export!
      expire_cache!

      export.batches.map(&:fail_op!)
      export.fail_op!
    end

    def re_enqueue
      self.class.perform_in(REENQUEUE_DELAY, export.id)
    end

    def export_timeout?
      export.updated_at < TIMEOUT.ago
    end

    def export_in_progress?
      export.batches.in_progress.any?
    end

    def finish_export!
      expire_cache!

      export.finish!
    end

    def expire_cache!
      export.batches.each do |batch|
        key = BulkImports::BatchedRelationExportService.cache_key(export.id, batch.id)

        Gitlab::Cache::Import::Caching.expire(key, 0)
      end
    end
  end
end
