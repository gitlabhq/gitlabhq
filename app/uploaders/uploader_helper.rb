# Extra methods for uploader
module UploaderHelper
  IMAGE_EXT = %w[png jpg jpeg gif bmp tiff].freeze
  # We recommend using the .mp4 format over .mov. Videos in .mov format can
  # still be used but you really need to make sure they are served with the
  # proper MIME type video/mp4 and not video/quicktime or your videos won't play
  # on IE >= 9.
  # http://archive.sublimevideo.info/20150912/docs.sublimevideo.net/troubleshooting.html
  VIDEO_EXT = %w[mp4 m4v mov webm ogv].freeze
  # These extension types can contain dangerous code and should only be embedded inline with
  # proper filtering. They should always be tagged as "Content-Disposition: attachment", not "inline".
  DANGEROUS_EXT = %w[svg].freeze

  def image?
    extension_match?(IMAGE_EXT)
  end

  def video?
    extension_match?(VIDEO_EXT)
  end

  def image_or_video?
    image? || video?
  end

  def dangerous?
    extension_match?(DANGEROUS_EXT)
  end

  private

  def extension_match?(extensions)
    return false unless file

    extension = file.try(:extension) || File.extname(file.path).delete('.')
    extensions.include?(extension.downcase)
  end
end
