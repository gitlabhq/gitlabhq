# frozen_string_literal: true

# Concern that sets the backoff delay to geo related workers
module GeoBackoffDelay
  extend ActiveSupport::Concern

  BACKOFF_TIME = 5.minutes

  included do
    def set_backoff_time!
      Rails.cache.write(skip_cache_key, true, expires_in: BACKOFF_TIME)
    end

    def skip_cache_key
      "#{self.class.name.underscore}:skip"
    end

    def should_be_skipped?
      Rails.cache.read(skip_cache_key)
    end
  end
end
