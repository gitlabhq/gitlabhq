# frozen_string_literal: true

class CustomEmoji < ApplicationRecord
  NAME_REGEXP = /[a-z0-9_-]+/.freeze

  belongs_to :namespace, inverse_of: :custom_emoji

  belongs_to :group, -> { where(type: 'Group') }, foreign_key: 'namespace_id'
  belongs_to :creator, class_name: "User", inverse_of: :created_custom_emoji

  # For now only external emoji are supported. See https://gitlab.com/gitlab-org/gitlab/-/issues/230467
  validates :external, inclusion: { in: [true] }

  validates :file, public_url: true, if: :external

  validate :valid_emoji_name

  validates :group, presence: true
  validates :creator, presence: true
  validates :name,
    uniqueness: { scope: [:namespace_id, :name] },
    presence: true,
    length: { maximum: 36 },

    format: { with: /\A#{NAME_REGEXP}\z/ }

  scope :by_name, -> (names) { where(name: names) }

  alias_attribute :url, :file # this might need a change in https://gitlab.com/gitlab-org/gitlab/-/issues/230467

  private

  def valid_emoji_name
    if Gitlab::Emoji.emoji_exists?(name)
      errors.add(:name, _('%{name} is already being used for another emoji') % { name: self.name })
    end
  end
end
