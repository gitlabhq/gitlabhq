class Appearance < ActiveRecord::Base
  include CacheMarkdownField
  include AfterCommitQueue
  include ObjectStorage::BackgroundMove

  cache_markdown_field :description
  cache_markdown_field :new_project_guidelines
  cache_markdown_field :header_message
  cache_markdown_field :footer_message

  validates :background_color, allow_blank: true, color: true
  validates :font_color,  allow_blank: true, color: true
  validates :logo,        file_size: { maximum: 1.megabyte }
  validates :header_logo, file_size: { maximum: 1.megabyte }

  validate :single_appearance_row, on: :create

  default_value_for :background_color, '#E75E40'
  default_value_for :font_color,  '#FFFFFF'

  mount_uploader :logo,         AttachmentUploader
  mount_uploader :header_logo,  AttachmentUploader

  has_many :uploads, as: :model, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  CACHE_KEY = 'current_appearance'.freeze

  after_commit :flush_redis_cache

  def self.current
    Rails.cache.fetch(CACHE_KEY) { first }
  end

  def flush_redis_cache
    Rails.cache.delete(CACHE_KEY)
  end

  def single_appearance_row
    if self.class.any?
      errors.add(:single_appearance_row, 'Only 1 appearances row can exist')
    end
  end
end
