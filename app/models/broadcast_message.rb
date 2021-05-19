# frozen_string_literal: true

class BroadcastMessage < ApplicationRecord
  include CacheMarkdownField
  include Sortable

  cache_markdown_field :message, pipeline: :broadcast_message, whitelisted: true

  validates :message,   presence: true
  validates :starts_at, presence: true
  validates :ends_at,   presence: true
  validates :broadcast_type, presence: true

  validates :color, allow_blank: true, color: true
  validates :font,  allow_blank: true, color: true

  default_value_for :color, '#E75E40'
  default_value_for :font,  '#FFFFFF'

  CACHE_KEY = 'broadcast_message_current_json'
  BANNER_CACHE_KEY = 'broadcast_message_current_banner_json'
  NOTIFICATION_CACHE_KEY = 'broadcast_message_current_notification_json'

  after_commit :flush_redis_cache

  enum broadcast_type: {
    banner: 1,
    notification: 2
  }

  class << self
    def current_banner_messages(current_path = nil)
      fetch_messages BANNER_CACHE_KEY, current_path do
        current_and_future_messages.banner
      end
    end

    def current_notification_messages(current_path = nil)
      fetch_messages NOTIFICATION_CACHE_KEY, current_path do
        current_and_future_messages.notification
      end
    end

    def current(current_path = nil)
      fetch_messages CACHE_KEY, current_path do
        current_and_future_messages
      end
    end

    def current_and_future_messages
      where('ends_at > :now', now: Time.current).order_id_asc
    end

    def cache
      ::Gitlab::SafeRequestStore.fetch(:broadcast_message_json_cache) do
        Gitlab::JsonCache.new(cache_key_with_version: false)
      end
    end

    def cache_expires_in
      2.weeks
    end

    private

    def fetch_messages(cache_key, current_path)
      messages = cache.fetch(cache_key, as: BroadcastMessage, expires_in: cache_expires_in) do
        yield
      end

      now_or_future = messages.select(&:now_or_future?)

      # If there are cached entries but they don't match the ones we are
      # displaying we'll refresh the cache so we don't need to keep filtering.
      cache.expire(cache_key) if now_or_future != messages

      now_or_future.select(&:now?).select { |message| message.matches_current_path(current_path) }
    end
  end

  def active?
    started? && !ended?
  end

  def started?
    Time.current >= starts_at
  end

  def ended?
    ends_at < Time.current
  end

  def now?
    (starts_at..ends_at).cover?(Time.current)
  end

  def future?
    starts_at > Time.current
  end

  def now_or_future?
    now? || future?
  end

  def matches_current_path(current_path)
    return false if current_path.blank? && target_path.present?
    return true if current_path.blank? || target_path.blank?

    # Ensure paths are consistent across callers.
    # This fixes a mismatch between requests in the GUI and CLI
    #
    # This has to be reassigned due to frozen strings being provided.
    unless current_path.start_with?("/")
      current_path = "/#{current_path}"
    end

    escaped = Regexp.escape(target_path).gsub('\\*', '.*')
    regexp = Regexp.new "^#{escaped}$", Regexp::IGNORECASE

    regexp.match(current_path)
  end

  def flush_redis_cache
    [CACHE_KEY, BANNER_CACHE_KEY, NOTIFICATION_CACHE_KEY].each do |key|
      self.class.cache.expire(key)
    end
  end
end

BroadcastMessage.prepend_mod_with('BroadcastMessage')
