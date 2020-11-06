# frozen_string_literal: true

class BulkImportWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :importers

  sidekiq_options retry: false, dead: false

  worker_has_external_dependencies!

  def perform(bulk_import_id)
    BulkImports::Importers::GroupsImporter.new(bulk_import_id).execute
  end
end
