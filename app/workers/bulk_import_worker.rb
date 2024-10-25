# frozen_string_literal: true

class BulkImportWorker
  include ApplicationWorker

  data_consistency :sticky
  feature_category :importers
  sidekiq_options retry: 3, dead: false
  idempotent!

  sidekiq_retries_exhausted do |msg, exception|
    new.perform_failure(exception, msg['args'].first)
  end

  def perform(bulk_import_id)
    bulk_import = BulkImport.find_by_id(bulk_import_id)
    return unless bulk_import

    BulkImports::ProcessService.new(bulk_import).execute
  end

  def perform_failure(exception, bulk_import_id)
    bulk_import = BulkImport.find_by_id(bulk_import_id)

    Gitlab::ErrorTracking.track_exception(exception, bulk_import_id: bulk_import.id)

    bulk_import.fail_op
  end
end
