# frozen_string_literal: true

module BulkImports
  class ExportUpload < ApplicationRecord
    include WithUploads

    self.table_name = 'bulk_import_export_uploads'

    belongs_to :export, class_name: 'BulkImports::Export'
    belongs_to :batch, class_name: 'BulkImports::ExportBatch', optional: true

    mount_uploader :export_file, ExportUploader

    def retrieve_upload(_identifier, paths)
      Upload.find_by(model: self, path: paths)
    end
  end
end
