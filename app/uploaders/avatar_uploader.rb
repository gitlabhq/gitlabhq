class AvatarUploader < CarrierWave::Uploader::Base
  include UploaderHelper

  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def exists?
    model.avatar.file && model.avatar.file.exists?
  end
end
