# frozen_string_literal: true

class ImportExportUploader < AttachmentUploader
  EXTENSION_ALLOWLIST = %w[tar.gz gz].freeze

  def self.workhorse_local_upload_path
    File.join(options.storage_path, 'uploads', TMP_UPLOAD_PATH)
  end

  def extension_whitelist
    EXTENSION_ALLOWLIST
  end

  def move_to_cache
    # Exports create temporary files that we can safely move.
    # Imports may be from project templates that we want to copy.
    return super if mounted_as == :export_file

    false
  end

  def work_dir
    File.join(Settings.shared['path'], 'tmp', 'work')
  end

  def cache_dir
    File.join(Settings.shared['path'], 'tmp', 'cache')
  end
end
