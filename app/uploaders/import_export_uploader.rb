class ImportExportUploader < AttachmentUploader
  EXTENSION_WHITELIST = %w[tar.gz].freeze

  after :delete, :destroy_upload

  def extension_whitelist
    EXTENSION_WHITELIST
  end

  def move_to_store
    true
  end

  def move_to_cache
    false
  end

  private

  def remove_upload
    upload&.destroy
  end
end
