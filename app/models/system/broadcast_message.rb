# frozen_string_literal: true

module System
  class BroadcastMessage < ApplicationRecord
    include CacheMarkdownField
    include Sortable

    ALLOWED_TARGET_ACCESS_LEVELS = [
      Gitlab::Access::GUEST,
      Gitlab::Access::PLANNER,
      Gitlab::Access::REPORTER,
      Gitlab::Access::DEVELOPER,
      Gitlab::Access::MAINTAINER,
      Gitlab::Access::OWNER
    ].freeze

    cache_markdown_field :message, pipeline: :broadcast_message, whitelisted: true

    validates :message,   presence: true
    validates :starts_at, presence: true
    validates :ends_at,   presence: true
    validates :broadcast_type, presence: true
    validates :target_access_levels, inclusion: { in: ALLOWED_TARGET_ACCESS_LEVELS }
    validates :show_in_cli, allow_nil: false, inclusion: { in: [true, false], message: N_('must be a boolean value') }

    validates :color, allow_blank: true, color: true
    validates :font,  allow_blank: true, color: true

    attribute :color, default: '#E75E40'
    attribute :font, default: '#FFFFFF'

    has_many :broadcast_message_dismissals, class_name: 'Users::BroadcastMessageDismissal'

    scope :current_and_future_messages, -> { where('ends_at > :now', now: Time.current).order_id_asc }

    CACHE_KEY = 'broadcast_message_current_json'
    BANNER_CACHE_KEY = 'broadcast_message_current_banner_json'
    NOTIFICATION_CACHE_KEY = 'broadcast_message_current_notification_json'

    after_commit :flush_redis_cache

    enum theme: {
      indigo: 0,
      'light-indigo': 1,
      blue: 2,
      'light-blue': 3,
      green: 4,
      'light-green': 5,
      red: 6,
      'light-red': 7,
      dark: 8,
      light: 9
    }, _default: 0, _prefix: true

    enum broadcast_type: {
      banner: 1,
      notification: 2
    }

    class << self
      def current_banner_messages(current_path: nil, user_access_level: nil)
        fetch_messages BANNER_CACHE_KEY, current_path, user_access_level do
          current_and_future_messages.banner
        end
      end

      def current_show_in_cli_banner_messages(user_access_level: nil)
        current_banner_messages(user_access_level: user_access_level).select(&:show_in_cli?)
      end

      def current_notification_messages(current_path: nil, user_access_level: nil)
        fetch_messages NOTIFICATION_CACHE_KEY, current_path, user_access_level do
          current_and_future_messages.notification
        end
      end

      def current(current_path: nil, user_access_level: nil)
        fetch_messages CACHE_KEY, current_path, user_access_level do
          current_and_future_messages
        end
      end

      def cache
        ::Gitlab::SafeRequestStore.fetch(:broadcast_message_json_cache) do
          Gitlab::Cache::JsonCaches::JsonKeyed.new
        end
      end

      def cache_expires_in
        2.weeks
      end

      private

      def fetch_messages(cache_key, current_path, user_access_level, &block)
        messages = cache.fetch(cache_key, as: System::BroadcastMessage, expires_in: cache_expires_in, &block)

        now_or_future = messages.select(&:now_or_future?)

        # If there are cached entries but they don't match the ones we are
        # displaying we'll refresh the cache so we don't need to keep filtering.
        cache.expire(cache_key) if now_or_future != messages

        messages = now_or_future.select(&:now?)
        messages = messages.select do |message|
          message.matches_current_user_access_level?(user_access_level)
        end
        messages.select do |message|
          message.matches_current_path(current_path)
        end
      end
    end

    def active?
      started? && !ended?
    end

    def started?
      Time.current >= starts_at
    end

    def ended?
      ends_at.past?
    end

    def now?
      (starts_at..ends_at).cover?(Time.current)
    end

    def future?
      starts_at.future?
    end

    def now_or_future?
      now? || future?
    end

    def matches_current_user_access_level?(user_access_level)
      return true unless target_access_levels.present?

      target_access_levels.include? user_access_level
    end

    def matches_current_path(current_path)
      return false if current_path.blank? && target_path.present?
      return true if current_path.blank? || target_path.blank?

      # Ensure paths are consistent across callers.
      # This fixes a mismatch between requests in the GUI and CLI
      #
      # This has to be reassigned due to frozen strings being provided.
      current_path = "/#{current_path}" unless current_path.start_with?("/")

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
end

System::BroadcastMessage.prepend_mod_with('System::BroadcastMessage')
