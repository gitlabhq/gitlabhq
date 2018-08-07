# The ReactiveCaching concern is used to fetch some data in the background and
# store it in the Rails cache, keeping it up-to-date for as long as it is being
# requested.  If the data hasn't been requested for +reactive_cache_lifetime+,
# it stop being refreshed, and then be removed.
#
# Example of use:
#
#    class Foo < ActiveRecord::Base
#      include ReactiveCaching
#
#      self.reactive_cache_key = ->(thing) { ["foo", thing.id] }
#
#      after_save :clear_reactive_cache!
#
#      def calculate_reactive_cache
#        # Expensive operation here. The return value of this method is cached
#      end
#
#      def result
#        with_reactive_cache do |data|
#          # ...
#        end
#      end
#    end
#
# In this example, the first time `#result` is called, it will return `nil`.
# However, it will enqueue a background worker to call `#calculate_reactive_cache`
# and set an initial cache lifetime of ten minutes.
#
# Each time the background job completes, it stores the return value of
# `#calculate_reactive_cache`. It is also re-enqueued to run again after
# `reactive_cache_refresh_interval`, so keeping the stored value up to date.
# Calculations are never run concurrently.
#
# Calling `#result` while a value is in the cache will call the block given to
# `#with_reactive_cache`, yielding the cached value. It will also extend the
# lifetime by `reactive_cache_lifetime`.
#
# Once the lifetime has expired, no more background jobs will be enqueued and
# calling `#result` will again return `nil` - starting the process all over
# again
module ReactiveCaching
  extend ActiveSupport::Concern

  InvalidateReactiveCache = Class.new(StandardError)

  included do
    class_attribute :reactive_cache_lease_timeout

    class_attribute :reactive_cache_key
    class_attribute :reactive_cache_lifetime
    class_attribute :reactive_cache_refresh_interval

    # defaults
    self.reactive_cache_lease_timeout = 2.minutes

    self.reactive_cache_refresh_interval = 1.minute
    self.reactive_cache_lifetime = 10.minutes

    def calculate_reactive_cache(*args)
      raise NotImplementedError
    end

    def reactive_cache_updated(*args)
    end

    def with_reactive_cache(*args, &blk)
      unless within_reactive_cache_lifetime?(*args)
        refresh_reactive_cache!(*args)
        return nil
      end

      keep_alive_reactive_cache!(*args)

      begin
        data = Rails.cache.read(full_reactive_cache_key(*args))
        yield data if data.present?
      rescue InvalidateReactiveCache
        refresh_reactive_cache!(*args)
        nil
      end
    end

    def clear_reactive_cache!(*args)
      Rails.cache.delete(full_reactive_cache_key(*args))
      Rails.cache.delete(alive_reactive_cache_key(*args))
    end

    def exclusively_update_reactive_cache!(*args)
      locking_reactive_cache(*args) do
        if within_reactive_cache_lifetime?(*args)
          enqueuing_update(*args) do
            key = full_reactive_cache_key(*args)
            new_value = calculate_reactive_cache(*args)
            old_value = Rails.cache.read(key)
            Rails.cache.write(key, new_value)
            reactive_cache_updated(*args) if new_value != old_value
          end
        end
      end
    end

    private

    def refresh_reactive_cache!(*args)
      clear_reactive_cache!(*args)
      keep_alive_reactive_cache!(*args)
      ReactiveCachingWorker.perform_async(self.class, id, *args)
    end

    def keep_alive_reactive_cache!(*args)
      Rails.cache.write(alive_reactive_cache_key(*args), true, expires_in: self.class.reactive_cache_lifetime)
    end

    def full_reactive_cache_key(*qualifiers)
      prefix = self.class.reactive_cache_key
      prefix = prefix.call(self) if prefix.respond_to?(:call)

      ([prefix].flatten + qualifiers).join(':')
    end

    def alive_reactive_cache_key(*qualifiers)
      full_reactive_cache_key(*(qualifiers + ['alive']))
    end

    def locking_reactive_cache(*args)
      lease = Gitlab::ExclusiveLease.new(full_reactive_cache_key(*args), timeout: reactive_cache_lease_timeout)
      uuid = lease.try_obtain
      yield if uuid
    ensure
      Gitlab::ExclusiveLease.cancel(full_reactive_cache_key(*args), uuid)
    end

    def within_reactive_cache_lifetime?(*args)
      !!Rails.cache.read(alive_reactive_cache_key(*args))
    end

    def enqueuing_update(*args)
      yield
    ensure
      ReactiveCachingWorker.perform_in(self.class.reactive_cache_refresh_interval, self.class, id, *args)
    end
  end
end
