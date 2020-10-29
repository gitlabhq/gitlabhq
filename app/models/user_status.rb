# frozen_string_literal: true

class UserStatus < ApplicationRecord
  include CacheMarkdownField

  self.primary_key = :user_id

  DEFAULT_EMOJI = 'speech_balloon'

  belongs_to :user

  enum availability: { not_set: 0, busy: 1 }

  validates :user, presence: true
  validates :emoji, inclusion: { in: Gitlab::Emoji.emojis_names }
  validates :message, length: { maximum: 100 }, allow_blank: true

  cache_markdown_field :message, pipeline: :emoji
end
