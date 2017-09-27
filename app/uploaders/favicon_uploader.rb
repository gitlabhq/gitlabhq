class FaviconUploader < AttachmentUploader
  include CarrierWave::MiniMagick

  STATUS_ICON_NAMES = [
    :status_canceled,
    :status_created,
    :status_failed,
    :status_manual,
    :status_not_found,
    :status_pending,
    :status_running,
    :status_skipped,
    :status_success,
    :status_warning
  ].freeze

  version :default do
    process resize_to_fill: [32, 32]
    process convert: 'ico'

    def full_filename(filename)
      filename_for_different_format(super(filename), 'ico')
    end
  end

  STATUS_ICON_NAMES.each do |status_name|
    version status_name, from_version: :default do
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
      overlay_path = Rails.root.join("app/assets/images/ci_favicons/overlays/favicon_#{status_name}.png")
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
