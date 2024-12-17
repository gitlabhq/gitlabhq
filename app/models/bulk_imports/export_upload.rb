# frozen_string_literal: true

module BulkImports
  class ExportUpload < ApplicationRecord
    include WithUploads

    self.table_name = 'bulk_import_export_uploads'

    belongs_to :export, class_name: 'BulkImports::Export'
    belongs_to :batch, class_name: 'BulkImports::ExportBatch', optional: true

    mount_uploader :export_file, ExportUploader

    # This causes CarrierWave v1 and v3 (but not v2) to upload the file to
    # object storage *after* the database entry has been committed to the
    # database. This avoids idling in a transaction. Similar to `ImportExportUpload`.
    if Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_STORE_EXPORT_FILE_AFTER_COMMIT', true))
      skip_callback :save, :after, :store_export_file!
      set_callback :commit, :after, :store_export_file!
    end

    def retrieve_upload(_identifier, paths)
      Upload.find_by(model: self, path: paths)
    end

    def uploads_sharding_key
      {
        project_id: export&.project_id,
        namespace_id: export&.group_id
      }
    end
  end
end
