# frozen_string_literal: true

module MetricImageUploading
  extend ActiveSupport::Concern

  MAX_FILE_SIZE = 1.megabyte.freeze

  included do
    include Gitlab::FileTypeDetection
    include FileStoreMounter
    include WithUploads

    validates :file, presence: true
    validate :validate_file_is_image
    validates :url, length: { maximum: 255 }, public_url: { allow_blank: true }
    validates :url_text, length: { maximum: 128 }

    scope :order_created_at_asc, -> { order(created_at: :asc) }

    attribute :file_store, :integer, default: -> { MetricImageUploader.default_store }

    mount_file_store_uploader MetricImageUploader
  end

  def filename
    @filename ||= file&.filename
  end

  def file_path
    @file_path ||= begin
      return file&.url unless file&.upload

      # If we're using a CDN, we need to use the full URL
      asset_host = ActionController::Base.asset_host || Gitlab.config.gitlab.base_url

      Gitlab::Utils.append_path(asset_host, local_path)
    end
  end

  private

  def valid_file_extensions
    Gitlab::FileTypeDetection::SAFE_IMAGE_EXT
  end

  def validate_file_is_image
    unless image?
      message = _('does not have a supported extension. Only %{extension_list} are supported') % {
        extension_list: valid_file_extensions.to_sentence
      }
      errors.add(:file, message)
    end
  end
end
