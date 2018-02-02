class AvatarUploader < GitlabUploader
  include UploaderHelper
  include RecordsUploads::Concern
  include ObjectStorage::Concern
  prepend ObjectStorage::Extension::RecordsUploads

  def exists?
    model.avatar.file && model.avatar.file.present?
  end

  def move_to_store
    false
  end

  def move_to_cache
    false
  end

  private

  def dynamic_segment
    File.join(model.class.to_s.underscore, mounted_as.to_s, model.id.to_s)
  end
end
