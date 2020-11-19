# frozen_string_literal: true

class CustomEmoji < ApplicationRecord
  belongs_to :namespace, inverse_of: :custom_emoji

  belongs_to :group, -> { where(type: 'Group') }, foreign_key: 'namespace_id'

  # For now only external emoji are supported. See https://gitlab.com/gitlab-org/gitlab/-/issues/230467
  validates :external, inclusion: { in: [true] }

  validates :file, public_url: true, if: :external

  validate :valid_emoji_name

  validates :group, presence: true
  validates :name,
    uniqueness: { scope: [:namespace_id, :name] },
    presence: true,
    length: { maximum: 36 },
    format: { with: /\A([a-z0-9]+[-_]?)+[a-z0-9]+\z/ }

  private

  def valid_emoji_name
    if Gitlab::Emoji.emoji_exists?(name)
      errors.add(:name, _('%{name} is already being used for another emoji') % { name: self.name })
    end
  end
end
