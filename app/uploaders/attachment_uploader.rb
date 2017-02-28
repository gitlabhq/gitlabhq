class AttachmentUploader < GitlabUploader
  include UploaderHelper

  storage :file

  def store_dir
    "#{base_dir}/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
end
