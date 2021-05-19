# frozen_string_literal: true

module Groups
  class CountService < BaseCountService
    include Gitlab::Utils::StrongMemoize

    VERSION = 1
    CACHED_COUNT_THRESHOLD = 1000
    EXPIRATION_TIME = 24.hours

    attr_reader :group, :user

    def initialize(group, user = nil)
      @group = group
      @user = user
    end

    def count
      cached_count = Rails.cache.read(cache_key)
      return cached_count unless cached_count.blank?

      refresh_cache_over_threshold
    end

    def refresh_cache_over_threshold(key = nil)
      key ||= cache_key
      new_count = uncached_count

      if new_count > CACHED_COUNT_THRESHOLD
        update_cache_for_key(key) { new_count }
      else
        delete_cache
      end

      new_count
    end

    def cache_key(key_name = nil)
      key_name ||= cache_key_name

      ['groups', "#{issuable_key}_count_service", VERSION, group.id, key_name]
    end

    private

    def relation_for_count
      raise NotImplementedError
    end

    def cache_options
      super.merge({ expires_in: EXPIRATION_TIME })
    end

    def cache_key_name
      raise NotImplementedError, 'cache_key_name must be implemented and return a String'
    end

    def issuable_key
      raise NotImplementedError, 'issuable_key must be implemented and return a String'
    end
  end
end
