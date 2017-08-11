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

  CACHE_KEY = 'broadcast_message_current'.freeze

  after_commit :flush_redis_cache

  def self.current
    Rails.cache.fetch(CACHE_KEY) do
      where('ends_at > :now AND starts_at <= :now', now: Time.zone.now)
        .reorder(id: :asc)
        .to_a
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

  def flush_redis_cache
    Rails.cache.delete(CACHE_KEY)
  end
end
