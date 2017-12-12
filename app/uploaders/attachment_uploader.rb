class AttachmentUploader < GitlabUploader
  include RecordsUploads::Concern
  include ObjectStorage::Concern
  prepend ObjectStorage::Extension::RecordsUploads
  include UploaderHelper

  storage_options Gitlab.config.uploads

  private

  def dynamic_segment
    File.join(model.class.to_s.underscore, mounted_as.to_s, model.id.to_s)
  end
end
