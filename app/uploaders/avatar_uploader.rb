# frozen_string_literal: true

class AvatarUploader < GitlabUploader
  include UploaderHelper
  include RecordsUploads::Concern
  include ObjectStorage::Concern
  prepend ObjectStorage::Extension::RecordsUploads

  MIME_WHITELIST = %w[image/png image/jpeg image/gif image/bmp image/tiff image/vnd.microsoft.icon].freeze

  def exists?
    model.avatar.file && model.avatar.file.present?
  end

  def move_to_store
    false
  end

  def move_to_cache
    false
  end

  def absolute_path
    self.class.absolute_path(upload)
  end

  def mounted_as
    super || 'avatar'
  end

  def content_type_whitelist
    MIME_WHITELIST
  end

  private

  def dynamic_segment
    File.join(model.class.underscore, mounted_as.to_s, model.id.to_s)
  end
end
