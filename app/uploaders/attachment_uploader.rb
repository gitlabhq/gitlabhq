# encoding: utf-8

class AttachmentUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def image?
    img_ext = %w(png jpg jpeg gif bmp tiff)
    if file.respond_to?(:extension)
      img_ext.include?(file.extension.downcase)
    else
      # Not all CarrierWave storages respond to :extension
      ext = file.path.split('.').last.downcase
      img_ext.include?(ext)
    end
  rescue
    false
  end

  def secure_url
    Gitlab.config.gitlab.relative_url_root + "/files/#{model.class.to_s.underscore}/#{model.id}/#{file.filename}"
  end

  def file_storage?
    self.class.storage == CarrierWave::Storage::File
  end
end
