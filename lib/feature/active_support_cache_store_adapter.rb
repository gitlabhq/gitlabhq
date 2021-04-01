# frozen_string_literal: true

# rubocop:disable Gitlab/NamespacedClass
# This class was already nested this way before moving to a separate file
class Feature
  class ActiveSupportCacheStoreAdapter < Flipper::Adapters::ActiveSupportCacheStore
    def enable(feature, gate, thing)
      return super unless Feature.enabled?(:feature_flags_cache_stale_read_fix, default_enabled: :yaml)

      result = @adapter.enable(feature, gate, thing)
      @cache.write(key_for(feature.key), @adapter.get(feature), @write_options)
      result
    end

    def disable(feature, gate, thing)
      return super unless Feature.enabled?(:feature_flags_cache_stale_read_fix, default_enabled: :yaml)

      result = @adapter.disable(feature, gate, thing)
      @cache.write(key_for(feature.key), @adapter.get(feature), @write_options)
      result
    end

    def remove(feature)
      return super unless Feature.enabled?(:feature_flags_cache_stale_read_fix, default_enabled: :yaml)

      result = @adapter.remove(feature)
      @cache.delete(FeaturesKey)
      @cache.write(key_for(feature.key), {}, @write_options)
      result
    end
  end
end
# rubocop:disable Gitlab/NamespacedClass
