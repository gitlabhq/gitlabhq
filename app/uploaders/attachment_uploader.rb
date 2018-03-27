class AttachmentUploader < GitlabUploader
  include UploaderHelper
  include RecordsUploads::Concern

  storage :file

  private

  def dynamic_segment
    File.join(model.class.to_s.underscore, mounted_as.to_s, model.id.to_s)
  end
end
