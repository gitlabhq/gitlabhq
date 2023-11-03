# frozen_string_literal: true

class BulkImportWorker
  include ApplicationWorker

  data_consistency :always
  feature_category :importers
  sidekiq_options retry: false, dead: false
  idempotent!

  def perform(bulk_import_id)
    bulk_import = BulkImport.find_by_id(bulk_import_id)
    return unless bulk_import

    BulkImports::ProcessService.new(bulk_import).execute
  end
end
