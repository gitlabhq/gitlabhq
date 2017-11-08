require 'carrierwave/orm/activerecord'

class CustomEmoji < ActiveRecord::Base
  belongs_to :namespace

  mount_uploader :file, CustomEmojiUploader

  validates_integrity_of :file

  validate :file_type
  validate :valid_emoji_name

  validates :name,
    presence: true,
    length: { maximum: 36 },
    format: { with: /\A\w+\z/ }

  scope :for_namespace, ->(namespace_id) do
    where(namespace_id: Namespace.find_by_id(namespace_id).self_and_ancestors.select(:id))
  end

  def url
    "#{Rails.application.routes.url_helpers.root_url}#{file.url}"
  end

  private

  def file_type
    self.errors.add :file, _('Only images allowed') unless self.file.image?
  end

  def valid_emoji_name
    if taken_emoji_names.include?(name)
      self.errors.add(:name, _("#{self.name} is already being used for another emoji"))
    end
  end

  def taken_emoji_names
    Gitlab::Emoji.emojis_names +
      CustomEmoji.for_namespace(self.namespace_id).pluck(:name)
  end
end
