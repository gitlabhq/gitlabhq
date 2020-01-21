# frozen_string_literal: true

class Appearance < ApplicationRecord
  include CacheableAttributes
  include CacheMarkdownField
  include ObjectStorage::BackgroundMove
  include WithUploads

  cache_markdown_field :description
  cache_markdown_field :new_project_guidelines
  cache_markdown_field :header_message, pipeline: :broadcast_message
  cache_markdown_field :footer_message, pipeline: :broadcast_message

  validates :logo,        file_size: { maximum: 1.megabyte }
  validates :header_logo, file_size: { maximum: 1.megabyte }
  validates :message_background_color, allow_blank: true, color: true
  validates :message_font_color, allow_blank: true, color: true

  validate :single_appearance_row, on: :create

  default_value_for :title, ''
  default_value_for :description, ''
  default_value_for :new_project_guidelines, ''
  default_value_for :header_message, ''
  default_value_for :footer_message, ''
  default_value_for :message_background_color, '#E75E40'
  default_value_for :message_font_color, '#FFFFFF'
  default_value_for :email_header_and_footer_enabled, false

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

  def show_header?
    header_message.present?
  end

  def show_footer?
    footer_message.present?
  end

  private

  def logo_system_path(logo, mount_type)
    # Legacy attachments may not have have an associated Upload record,
    # so fallback to the AttachmentUploader#url if this is the
    # case. AttachmentUploader#path doesn't work because for a local
    # file, this is an absolute path to the file.
    return logo&.url unless logo&.upload

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
