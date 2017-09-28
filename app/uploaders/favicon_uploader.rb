class FaviconUploader < AttachmentUploader
  include CarrierWave::MiniMagick

  STATUS_ICON_NAMES = [
    :favicon_status_canceled,
    :favicon_status_created,
    :favicon_status_failed,
    :favicon_status_manual,
    :favicon_status_not_found,
    :favicon_status_pending,
    :favicon_status_running,
    :favicon_status_skipped,
    :favicon_status_success,
    :favicon_status_warning
  ].freeze

  version :favicon_main do
    process resize_to_fill: [32, 32]
    process convert: 'ico'

    def full_filename(filename)
      filename_for_different_format(super(filename), 'ico')
    end
  end

  STATUS_ICON_NAMES.each do |status_name|
    version status_name, from_version: :favicon_main do
      process status_favicon: status_name

      def full_filename(filename)
        filename_for_different_format(super(filename), 'ico')
      end
    end
  end

  def extension_whitelist
    UploaderHelper::IMAGE_EXT
  end

  private

  def status_favicon(status_name)
    manipulate! do |img|
      overlay_path = Rails.root.join("app/assets/images/ci_favicons/overlays/#{status_name}.png")
      overlay = MiniMagick::Image.open(overlay_path)
      img.composite(overlay) do |c|
        c.compose 'over'
      end
    end
  end

  def filename_for_different_format(filename, format)
    filename.chomp(File.extname(filename)) + ".#{format}"
  end
end
