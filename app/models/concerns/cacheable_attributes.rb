# frozen_string_literal: true

module CacheableAttributes
  extend ActiveSupport::Concern

  included do
    after_commit { self.class.expire }

    private_class_method :request_store_cache_key
  end

  class_methods do
    def cache_key
      "#{name}:#{Gitlab::VERSION}:#{Rails.version}"
    end

    # Can be overridden
    def current_without_cache
      last
    end

    # Can be overridden
    def defaults
      {}
    end

    def build_from_defaults(attributes = {})
      final_attributes = defaults
        .merge(attributes)
        .stringify_keys
        .slice(*column_names)

      new(final_attributes)
    end

    def cached
      Gitlab::SafeRequestStore[request_store_cache_key] ||= retrieve_from_cache
    end

    def request_store_cache_key
      :"#{name}_cached_attributes"
    end

    def retrieve_from_cache
      record = cache_backend.read(cache_key)
      ensure_cache_setup if record.present?

      record
    end

    def current
      cached_record = cached
      return cached_record if cached_record.present?

      current_without_cache.tap { |current_record| current_record&.cache! }
    rescue StandardError => e
      if Rails.env.production?
        Gitlab::AppLogger.warn("Cached record for #{name} couldn't be loaded, falling back to uncached record: #{e}")
      else
        raise e
      end
      # Fall back to an uncached value if there are any problems (e.g. Redis down)
      current_without_cache
    end

    def expire
      Gitlab::SafeRequestStore.delete(request_store_cache_key)
      cache_backend.delete(cache_key)
    rescue StandardError
      # Gracefully handle when Redis is not available. For example,
      # omnibus may fail here during gitlab:assets:compile.
    end

    def ensure_cache_setup
      # This is a workaround for a Rails bug that causes attribute methods not
      # to be loaded when read from cache: https://github.com/rails/rails/issues/27348
      define_attribute_methods
    end

    def cache_backend
      Rails.cache
    end
  end

  def cache!
    self.class.cache_backend.write(self.class.cache_key, self, expires_in: Gitlab.config.gitlab['application_settings_cache_seconds'] || 60)
  end
end
