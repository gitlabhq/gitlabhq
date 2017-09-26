class Appearance < ActiveRecord::Base
  include CacheableAttributes
  include CacheMarkdownField
  include ObjectStorage::BackgroundMove
  include WithUploads

  prepend EE::Appearance

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
end
