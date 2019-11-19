# frozen_string_literal: true

class ImportExportUpload < ApplicationRecord
  include WithUploads
  include ObjectStorage::BackgroundMove

  belongs_to :project
  belongs_to :group

  # These hold the project Import/Export archives (.tar.gz files)
  mount_uploader :import_file, ImportExportUploader
  mount_uploader :export_file, ImportExportUploader

  def retrieve_upload(_identifier, paths)
    Upload.find_by(model: self, path: paths)
  end
end
