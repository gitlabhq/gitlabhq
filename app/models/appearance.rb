# frozen_string_literal: true

class Appearance < ActiveRecord::Base
  include CacheableAttributes
  include CacheMarkdownField
  include ObjectStorage::BackgroundMove
  include WithUploads

  cache_markdown_field :description
  cache_markdown_field :new_project_guidelines

  validates :logo,        file_size: { maximum: 1.megabyte }
  validates :header_logo, file_size: { maximum: 1.megabyte }

  validate :single_appearance_row, on: :create

  mount_uploader :logo,         AttachmentUploader
  mount_uploader :header_logo,  AttachmentUploader
  mount_uploader :favicon,      FaviconUploader

  # Overrides CacheableAttributes.current_without_cache
  def self.current_without_cache
    first
  end

  def single_appearance_row
    if self.class.any?
      errors.add(:single_appearance_row, 'Only 1 appearances row can exist')
    end
  end

  def logo_path
    logo_system_path(logo, 'logo')
  end

  def header_logo_path
    logo_system_path(header_logo, 'header_logo')
  end

  def favicon_path
    logo_system_path(favicon, 'favicon')
  end

  private

  def logo_system_path(logo, mount_type)
    return unless logo&.upload

    # If we're using a CDN, we need to use the full URL
    asset_host = ActionController::Base.asset_host
    local_path = Gitlab::Routing.url_helpers.appearance_upload_path(
      filename: logo.filename,
      id: logo.upload.model_id,
      model: 'appearance',
      mounted_as: mount_type)

    Gitlab::Utils.append_path(asset_host, local_path)
  end
end
