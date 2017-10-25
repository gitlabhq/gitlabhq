require 'carrierwave/orm/activerecord'

class CustomEmoji < ActiveRecord::Base
  belongs_to :namespace

  mount_uploader :file, CustomEmojiUploader

  validates_integrity_of :file

  validate :file_type
  validate :valid_emoji_name

  validates :name,
    presence: true,
    uniqueness: { scope: :namespace_id },
    length: { maximum: 36 },
    format: { with: /\A\w+\z/ }

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

  def valid_emoji_name
    valid_emoji = Gitlab::Emoji.emojis_names
    valid_emoji += namespace.custom_emoji_url_by_name.keys

    if valid_emoji.include?(name)
      self.errors.add(:name, "#{self.name} is already being used for another emoji")
    end
  end
end
