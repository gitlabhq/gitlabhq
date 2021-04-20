# frozen_string_literal: true

# rubocop:disable Gitlab/NamespacedClass
# This class was already nested this way before moving to a separate file
class Feature
  class ActiveSupportCacheStoreAdapter < Flipper::Adapters::ActiveSupportCacheStore
    def enable(feature, gate, thing)
      result = @adapter.enable(feature, gate, thing)
      @cache.write(key_for(feature.key), @adapter.get(feature), @write_options)
      result
    end

    def disable(feature, gate, thing)
      result = @adapter.disable(feature, gate, thing)
      @cache.write(key_for(feature.key), @adapter.get(feature), @write_options)
      result
    end

    def remove(feature)
      result = @adapter.remove(feature)
      @cache.delete(FeaturesKey)
      @cache.write(key_for(feature.key), {}, @write_options)
      result
    end
  end
end
# rubocop:disable Gitlab/NamespacedClass
