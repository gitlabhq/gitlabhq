class FaviconUploader < AttachmentUploader
  include CarrierWave::MiniMagick

  version :favicon_main do
    process resize_to_fill: [32, 32]
    process convert: 'png'

    def full_filename(filename)
      filename_for_different_format(super(filename), 'png')
    end
  end

  def extension_whitelist
    UploaderHelper::IMAGE_EXT
  end

  private

  def filename_for_different_format(filename, format)
    filename.chomp(File.extname(filename)) + ".#{format}"
  end
end
