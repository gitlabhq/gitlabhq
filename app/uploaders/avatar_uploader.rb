# frozen_string_literal: true

class AvatarUploader < GitlabUploader
  include UploaderHelper
  include RecordsUploads::Concern
  include ObjectStorage::Concern
  prepend ObjectStorage::Extension::RecordsUploads
  include UploadTypeCheck::Concern

  check_upload_type extensions: AvatarUploader::SAFE_IMAGE_EXT

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

  private

  def dynamic_segment
    File.join(model.class.underscore, mounted_as.to_s, model.id.to_s)
  end
end
