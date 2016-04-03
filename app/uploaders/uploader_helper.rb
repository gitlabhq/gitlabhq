# Extra methods for uploader
module UploaderHelper
  IMAGE_EXT = %w(png jpg jpeg gif bmp tiff)
  VIDEO_EXT = %w(mov mp4 ogg webm flv)

  def image?
    extension_match?(IMAGE_EXT)
  rescue
    false
  end

  def video?
    extension_match?(VIDEO_EXT)
  rescue
    false
  end

  def image_or_video?
    image? || video?
  end

  def extension_match?(extensions)
    if file.respond_to?(:extension)
      extensions.include?(file.extension.downcase)
    else
      # Not all CarrierWave storages respond to :extension
      ext = file.path.split('.').last.downcase
      extensions.include?(ext)
    end
  end

  def file_storage?
    self.class.storage == CarrierWave::Storage::File
  end
end
