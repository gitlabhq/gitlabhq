# frozen_string_literal: true

module BulkImports
  class ExportUpload < ApplicationRecord
    include WithUploads
    include ObjectStorage::BackgroundMove

    self.table_name = 'bulk_import_export_uploads'

    belongs_to :export, class_name: 'BulkImports::Export'

    mount_uploader :export_file, ExportUploader

    def retrieve_upload(_identifier, paths)
      Upload.find_by(model: self, path: paths)
    end
  end
end
