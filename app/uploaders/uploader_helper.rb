# Extra methods for uploader
module UploaderHelper
  IMAGE_EXT = %w[png jpg jpeg gif bmp tiff]
  # We recommend using the .mp4 format over .mov. Videos in .mov format can
  # still be used but you really need to make sure they are served with the
  # proper MIME type video/mp4 and not video/quicktime or your videos won't play
  # on IE >= 9.
  # http://archive.sublimevideo.info/20150912/docs.sublimevideo.net/troubleshooting.html
  VIDEO_EXT = %w[mp4 m4v mov webm ogv]

  def image?
    extension_match?(IMAGE_EXT)
  end

  def video?
    extension_match?(VIDEO_EXT)
  end

  def image_or_video?
    image? || video?
  end

  def extension_match?(extensions)
    return false unless file

    extension =
      if file.respond_to?(:extension)
        file.extension
      else
        # Not all CarrierWave storages respond to :extension
        File.extname(file.path).delete('.')
      end

    extensions.include?(extension.downcase)
  end

  def file_storage?
    self.class.storage == CarrierWave::Storage::File
  end
end
