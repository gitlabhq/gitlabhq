module CacheableAttributes
  extend ActiveSupport::Concern

  included do
    after_commit { self.class.expire }
  end

  class_methods do
    # Can be overriden
    def current_without_cache
      last
    end

    def cache_key
      "#{name}:#{Gitlab::VERSION}:#{Gitlab.migrations_hash}:json".freeze
    end

    def defaults
      {}
    end

    def build_from_defaults(attributes = {})
      new(defaults.merge(attributes))
    end

    def cached
      json_attributes = Rails.cache.read(cache_key)
      return nil unless json_attributes.present?

      build_from_defaults(JSON.parse(json_attributes))
    end

    def current
      cached_record = cached
      return cached_record if cached_record.present?

      current_without_cache.tap { |current_record| current_record&.cache! }
    rescue
      # Fall back to an uncached value if there are any problems (e.g. Redis down)
      current_without_cache
    end

    def expire
      Rails.cache.delete(cache_key)
    rescue
      # Gracefully handle when Redis is not available. For example,
      # omnibus may fail here during gitlab:assets:compile.
    end
  end

  def cache!
    Rails.cache.write(self.class.cache_key, attributes.to_json)
  end
end
