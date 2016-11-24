class BroadcastMessage < ActiveRecord::Base
  include CacheMarkdownField
  include Sortable

  cache_markdown_field :message, pipeline: :broadcast_message

  validates :message,   presence: true
  validates :starts_at, presence: true
  validates :ends_at,   presence: true

  validates :color, allow_blank: true, color: true
  validates :font,  allow_blank: true, color: true

  default_value_for :color, '#E75E40'
  default_value_for :font,  '#FFFFFF'

  def self.current
    Rails.cache.fetch("broadcast_message_current", expires_in: 1.minute) do
      where("ends_at > :now AND starts_at <= :now", now: Time.zone.now).last
    end
  end

  def active?
    started? && !ended?
  end

  def started?
    Time.zone.now >= starts_at
  end

  def ended?
    ends_at < Time.zone.now
  end
end
