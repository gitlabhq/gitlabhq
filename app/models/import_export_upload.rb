# frozen_string_literal: true

class ImportExportUpload < ActiveRecord::Base
  include WithUploads
  include ObjectStorage::BackgroundMove

  belongs_to :project

  mount_uploader :import_file, ImportExportUploader
  mount_uploader :export_file, ImportExportUploader

  def retrieve_upload(_identifier, paths)
    Upload.find_by(model: self, path: paths)
  end
end
