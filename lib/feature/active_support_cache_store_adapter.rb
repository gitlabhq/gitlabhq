# frozen_string_literal: true

# rubocop:disable Gitlab/NamespacedClass
# This class was already nested this way before moving to a separate file
class Feature
  class ActiveSupportCacheStoreAdapter < Flipper::Adapters::ActiveSupportCacheStore
    # This patch represents https://github.com/jnunemaker/flipper/pull/512. In
    # Flipper 0.21.0 and later, we can remove this and just pass `write_through:
    # true` to the constructor in `Feature.build_flipper_instance`.

    extend ::Gitlab::Utils::Override

    override :enable
    def enable(feature, gate, thing)
      result = @adapter.enable(feature, gate, thing)
      @cache.write(key_for(feature.key), @adapter.get(feature), @write_options)
      result
    end

    override :disable
    def disable(feature, gate, thing)
      result = @adapter.disable(feature, gate, thing)
      @cache.write(key_for(feature.key), @adapter.get(feature), @write_options)
      result
    end

    override :remove
    def remove(feature)
      result = @adapter.remove(feature)
      @cache.delete(FeaturesKey)
      @cache.write(key_for(feature.key), {}, @write_options)
      result
    end
  end
end
# rubocop:disable Gitlab/NamespacedClass
