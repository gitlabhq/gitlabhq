# frozen_string_literal: true

class UserStatus < ApplicationRecord
  include CacheMarkdownField

  self.primary_key = :user_id

  DEFAULT_EMOJI = 'speech_balloon'

  CLEAR_STATUS_QUICK_OPTIONS = {
    '30_minutes' => 30.minutes,
    '3_hours' => 3.hours,
    '8_hours' => 8.hours,
    '1_day' => 1.day,
    '3_days' => 3.days,
    '7_days' => 7.days,
    '30_days' => 30.days
  }.freeze

  belongs_to :user, inverse_of: :status

  enum availability: { not_set: 0, busy: 1 }

  validates :user, presence: true
  validates :emoji, 'gitlab/emoji_name': true
  validates :message, length: { maximum: 100 }, allow_blank: true

  scope :scheduled_for_cleanup, -> { where(arel_table[:clear_status_at].lteq(Time.current)) }

  cache_markdown_field :message, pipeline: :emoji

  def clear_status_after
    clear_status_at
  end

  def clear_status_after=(value)
    self.clear_status_at = CLEAR_STATUS_QUICK_OPTIONS[value]&.from_now
  end

  def customized?
    message.present? || emoji != UserStatus::DEFAULT_EMOJI
  end
end

UserStatus.prepend_mod_with('UserStatus')
