# frozen_string_literal: true

module EE
  module Feature
    module ClassMethods
      extend ::Gitlab::Utils::Override

      override :enable
      def enable(key, thing = true)
        super
        log_geo_event(key)
      end

      override :disable
      def disable(key, thing = false)
        super
        log_geo_event(key)
      end

      override :enable_group
      def enable_group(key, group)
        super
        log_geo_event(key)
      end

      override :disable_group
      def disable_group(key, group)
        super
        log_geo_event(key)
      end

      private

      def log_geo_event(key)
        Geo::CacheInvalidationEventStore.new(cache_store.key_for(key)).create!
      end

      def cache_store
        Flipper::Adapters::ActiveSupportCacheStore
      end
    end

    def self.prepended(base)
      base.singleton_class.prepend ClassMethods
    end
  end
end
