# frozen_string_literal: true

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

  CACHE_KEY = 'broadcast_message_current_json'.freeze
  LEGACY_CACHE_KEY = 'broadcast_message_current'.freeze

  after_commit :flush_redis_cache

  def self.current
    raw_messages = Rails.cache.fetch(CACHE_KEY, expires_in: cache_expires_in) do
      remove_legacy_cache_key
      current_and_future_messages.to_json
    end

    messages = decode_messages(raw_messages)

    return [] unless messages&.present?

    now_or_future = messages.select(&:now_or_future?)

    # If there are cached entries but none are to be displayed we'll purge the
    # cache so we don't keep running this code all the time.
    Rails.cache.delete(CACHE_KEY) if now_or_future.empty?

    now_or_future.select(&:now?)
  end

  def self.decode_messages(raw_messages)
    return unless raw_messages&.present?

    message_list = ActiveSupport::JSON.decode(raw_messages)

    return unless message_list.is_a?(Array)

    valid_attr = BroadcastMessage.attribute_names

    message_list.map do |raw|
      BroadcastMessage.new(raw) if valid_cache_entry?(raw, valid_attr)
    end.compact
  rescue ActiveSupport::JSON.parse_error
  end

  def self.valid_cache_entry?(raw, valid_attr)
    return false unless raw.is_a?(Hash)

    (raw.keys - valid_attr).empty?
  end

  def self.current_and_future_messages
    where('ends_at > :now', now: Time.zone.now).order_id_asc
  end

  def self.cache_expires_in
    nil
  end

  # This can be removed in GitLab 12.0+
  # The old cache key had an indefinite lifetime, and in an HA
  # environment a one-shot migration would not work because the cache
  # would be repopulated by a node that has not been upgraded.
  def self.remove_legacy_cache_key
    Rails.cache.delete(LEGACY_CACHE_KEY)
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
    self.class.remove_legacy_cache_key
  end
end
