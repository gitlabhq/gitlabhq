# frozen_string_literal: true

class BroadcastMessage < ApplicationRecord
  include CacheMarkdownField
  include Sortable

  cache_markdown_field :message, pipeline: :broadcast_message, whitelisted: true

  validates :message,   presence: true
  validates :starts_at, presence: true
  validates :ends_at,   presence: true

  validates :color, allow_blank: true, color: true
  validates :font,  allow_blank: true, color: true

  default_value_for :color, '#E75E40'
  default_value_for :font,  '#FFFFFF'

  CACHE_KEY = 'broadcast_message_current_json'

  after_commit :flush_redis_cache

  def self.current(current_path = nil)
    messages = cache.fetch(CACHE_KEY, as: BroadcastMessage, expires_in: cache_expires_in) do
      current_and_future_messages
    end

    return [] unless messages&.present?

    now_or_future = messages.select(&:now_or_future?)

    # If there are cached entries but none are to be displayed we'll purge the
    # cache so we don't keep running this code all the time.
    cache.expire(CACHE_KEY) if now_or_future.empty?

    now_or_future.select(&:now?).select { |message| message.matches_current_path(current_path) }
  end

  def self.current_and_future_messages
    where('ends_at > :now', now: Time.zone.now).order_id_asc
  end

  def self.cache
    Gitlab::JsonCache.new(cache_key_with_version: false)
  end

  def self.cache_expires_in
    2.weeks
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

  def matches_current_path(current_path)
    return true if current_path.blank? || target_path.blank?

    current_path.match(Regexp.escape(target_path).gsub('\\*', '.*'))
  end

  def flush_redis_cache
    self.class.cache.expire(CACHE_KEY)
  end
end

BroadcastMessage.prepend_if_ee('EE::BroadcastMessage')
