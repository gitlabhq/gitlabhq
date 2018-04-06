class Appearance < ActiveRecord::Base
  include CacheMarkdownField
  include AfterCommitQueue
  include ObjectStorage::BackgroundMove

  prepend EE::Appearance

  cache_markdown_field :description
  cache_markdown_field :new_project_guidelines

  validates :logo,        file_size: { maximum: 1.megabyte }
  validates :header_logo, file_size: { maximum: 1.megabyte }

  validate :single_appearance_row, on: :create

  mount_uploader :logo,         AttachmentUploader
  mount_uploader :header_logo,  AttachmentUploader

  has_many :uploads, as: :model, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  CACHE_KEY = "current_appearance:#{Gitlab::VERSION}".freeze

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
