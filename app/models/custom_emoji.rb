require 'carrierwave/orm/activerecord'

class CustomEmoji < ActiveRecord::Base
  MAXIMUM = 100

  belongs_to :namespace

  mount_uploader :file, CustomEmojiUploader

  validates_integrity_of :file

  validates :name,
    presence: true,
    uniqueness: { scope: :namespace_id },
    length: { maximum: 36 },
    format: { with: /\A\w+\z/ },
    exclusion: { in: Gitlab::Emoji.emojis_names }

  validate :file_type

  before_create :limit_reached
  after_save :expire_cache

  def url
    "#{Rails.application.routes.url_helpers.root_url}#{file.url}"
  end

  private

  def limit_reached
    self.errors.add :custom_emoji, 'Custom emoji limit reached' unless self.namespace.custom_emoji.count < MAXIMUM
  end

  def expire_cache
    namespace.invalidate_custom_emoji_cache
  end

  def file_type
    self.errors.add :file, 'Only images allowed' unless self.file.image?
  end
end
