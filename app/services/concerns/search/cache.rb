# frozen_string_literal: true

module Search
  class Cache
    DEFAULT_EXPIRES_IN = 1.minute

    def self.lookup(...)
      new(...).lookup { yield }
    end

    attr_reader :cache_key, :expires_in, :enabled

    def initialize(resource:, action:, expires_in: DEFAULT_EXPIRES_IN, cache_key: nil, enabled: true)
      @cache_key = cache_key || generate_cache_key(resource, action)
      @expires_in = expires_in
      @enabled = enabled
    end

    def lookup
      return yield unless enabled

      Rails.cache.fetch(cache_key, expires_in: expires_in) { yield }
    end

    private

    def generate_cache_key(resource, action)
      "search_#{resource.class.name.downcase}_#{resource.id}_#{action}"
    end
  end
end
