# frozen_string_literal: true

class CustomEmoji < ApplicationRecord
  belongs_to :namespace, inverse_of: :custom_emoji

  validate :valid_emoji_name

  validates :namespace, presence: true
  validates :name,
    uniqueness: { scope: [:namespace_id, :name] },
    presence: true,
    length: { maximum: 36 },
    format: { with: /\A\w+\z/ }

  private

  def valid_emoji_name
    if Gitlab::Emoji.emoji_exists?(name)
      errors.add(:name, _('%{name} is already being used for another emoji') % { name: self.name })
    end
  end
end
