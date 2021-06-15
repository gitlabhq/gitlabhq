# frozen_string_literal: true

class ImportExportUpload < ApplicationRecord
  include WithUploads
  include ObjectStorage::BackgroundMove

  belongs_to :project
  belongs_to :group

  # These hold the project Import/Export archives (.tar.gz files)
  mount_uploader :import_file, ImportExportUploader
  mount_uploader :export_file, ImportExportUploader

  # This causes CarrierWave v1 and v3 (but not v2) to upload the file to
  # object storage *after* the database entry has been committed to the
  # database. This avoids idling in a transaction.
  if Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_STORE_EXPORT_FILE_AFTER_COMMIT', true))
    skip_callback :save, :after, :store_export_file!
    set_callback :commit, :after, :store_export_file!
  end

  scope :updated_before, ->(date) { where('updated_at < ?', date) }
  scope :with_export_file, -> { where.not(export_file: nil) }

  def retrieve_upload(_identifier, paths)
    Upload.find_by(model: self, path: paths)
  end

  def export_file_exists?
    !!carrierwave_export_file
  end

  # This checks if the export archive is actually stored on disk. It
  # requires a HEAD request if object storage is used.
  def export_archive_exists?
    !!carrierwave_export_file&.exists?
  # Handle any HTTP unexpected error
  # https://github.com/excon/excon/blob/bbb5bd791d0bb2251593b80e3bce98dbec6e8f24/lib/excon/error.rb#L129-L169
  rescue Excon::Error => e
    # The HEAD request will fail with a 403 Forbidden if the file does not
    # exist, and the user does not have permission to list the object
    # storage bucket.
    Gitlab::ErrorTracking.track_exception(e)
    false
  end

  private

  def carrierwave_export_file
    export_file&.file
  end
end
