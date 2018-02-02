class AvatarUploader < GitlabUploader
  include UploaderHelper
  include RecordsUploads::Concern
<<<<<<< HEAD
  include ObjectStorage::Concern
  prepend ObjectStorage::Extension::RecordsUploads
=======

  storage :file
>>>>>>> upstream/master

  def exists?
    model.avatar.file && model.avatar.file.present?
  end

<<<<<<< HEAD
  def move_to_store
=======
  def move_to_cache
>>>>>>> upstream/master
    false
  end

  def move_to_store
    false
  end

  private

  def dynamic_segment
    File.join(model.class.to_s.underscore, mounted_as.to_s, model.id.to_s)
  end
end
