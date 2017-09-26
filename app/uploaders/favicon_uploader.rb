class FaviconUploader < AttachmentUploader
  include CarrierWave::MiniMagick

  STATUS_ICON_NAMES = [
    :status_not_found,
    :status_canceled,
    :status_success,
    :status_skipped,
    :status_created,
    :status_failed,
    :status_warning,
    :status_pending,
    :status_manual,
    :status_running
  ].freeze

  version :default_without_format_conversion do
    process resize_to_fill: [32, 32]
  end

  # this intermediate version generates an image in the ico format but with the
  # original file suffix.
  version :_default, from_version: :default_without_format_conversion do
    process convert: 'ico'
  end

  version :default, from_version: :_default

  STATUS_ICON_NAMES.each do |status_name|
    version status_name, from_version: :default do
      process status_favicon: status_name
    end
  end

  def status_favicon(status_name)
    manipulate! do |img|
      overlay_path = Rails.root.join("app/assets/images/ci_favicons/overlays/favicon_#{status_name}.png")
      overlay = MiniMagick::Image.open(overlay_path)
      img.composite(overlay) do |c|
        c.compose 'over'
      end
    end
  end
end
