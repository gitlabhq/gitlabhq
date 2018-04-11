class BroadcastMessage < ActiveRecord::Base
  prepend EE::BroadcastMessage
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
    messages = Rails.cache.fetch(CACHE_KEY, expires_in: cache_expires_in) { current_and_future_messages.to_a }

    return messages if messages.empty?

    now_or_future = messages.select(&:now_or_future?)

    # If there are cached entries but none are to be displayed we'll purge the
    # cache so we don't keep running this code all the time.
    Rails.cache.delete(CACHE_KEY) if now_or_future.empty?

    now_or_future.select(&:now?)
  end

  def self.current_and_future_messages
    where('ends_at > :now', now: Time.zone.now).order_id_asc
  end

  def self.cache_expires_in
    nil
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

  def now?
    (starts_at..ends_at).cover?(Time.zone.now)
  end

  def future?
    starts_at > Time.zone.now
  end

  def now_or_future?
    now? || future?
  end

  def flush_redis_cache
    Rails.cache.delete(CACHE_KEY)
  end
end
