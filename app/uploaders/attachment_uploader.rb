class AttachmentUploader < GitlabUploader
<<<<<<< HEAD
  include RecordsUploads::Concern
  include ObjectStorage::Concern
  prepend ObjectStorage::Extension::RecordsUploads
=======
>>>>>>> upstream/master
  include UploaderHelper
  include RecordsUploads::Concern

  private

<<<<<<< HEAD
=======
  private

>>>>>>> upstream/master
  def dynamic_segment
    File.join(model.class.to_s.underscore, mounted_as.to_s, model.id.to_s)
  end
end
