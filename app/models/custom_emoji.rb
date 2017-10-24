require 'carrierwave/orm/activerecord'

class CustomEmoji < ActiveRecord::Base
  belongs_to :namespace

  mount_uploader :file, CustomEmojiUploader

  validates_integrity_of :file

  validate :file_type
  validates :name,
    presence: true,
    uniqueness: { scope: :namespace_id },
    length: { maximum: 36 },
    format: { with: /\A\w+\z/ },
    exclusion: { in: Gitlab::Emoji.emojis_names }

  after_save :expire_cache

  scope :for_namespace, ->(namespace_id) do
    where(namespace_id: Namespace.find_by_id(namespace_id).self_and_ancestors.select(:id))
  end

  def url
    "#{Rails.application.routes.url_helpers.root_url}#{file.url}"
  end

  private

  def expire_cache
    namespace.invalidate_custom_emoji_cache
  end

  def file_type
    self.errors.add :file, 'Only images allowed' unless self.file.image?
  end
end
