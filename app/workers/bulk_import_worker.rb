# frozen_string_literal: true

class BulkImportWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :importers

  sidekiq_options retry: false, dead: false

  worker_has_external_dependencies!

  def perform(bulk_import_id)
    bulk_import = BulkImport.find_by_id(bulk_import_id)

    return unless bulk_import

    bulk_import.entities.each do |entity|
      entity.start!

      BulkImports::Importers::GroupImporter.new(entity.id).execute

      entity.finish!
    end

    bulk_import.finish!
  end
end
