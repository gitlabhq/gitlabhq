# frozen_string_literal: true

# Grape helpers for caching.
#
# This module helps introduce standardised caching into the Grape API
# in a similar manner to the standard Grape DSL.

module API
  module Helpers
    module Caching
      include Gitlab::Cache::Helpers
      # @return [Hash]
      DEFAULT_CACHE_OPTIONS = {
        race_condition_ttl: 5.seconds
      }.freeze

      # This is functionally equivalent to the standard `#present` used in
      # Grape endpoints, but the JSON for the object, or for each object of
      # a collection, will be cached.
      #
      # With a collection all the keys will be fetched in a single call and the
      # Entity rendered for those missing from the cache, which are then written
      # back into it.
      #
      # Both the single object, and all objects inside a collection, must respond
      # to `#cache_key`.
      #
      # To override the Grape formatter we return a custom wrapper in
      # `Gitlab::Json::PrecompiledJson` which tells the `Gitlab::Json::GrapeFormatter`
      # to export the string without conversion.
      #
      # A cache context can be supplied to add more context to the cache key. This
      # defaults to including the `current_user` in every key for safety, unless overridden.
      #
      # @param obj_or_collection [Object, Enumerable<Object>] the object or objects to render
      # @param with [Grape::Entity] the entity to use for rendering
      # @param cache_context [Proc] a proc to call for each object to provide more context to the cache key
      # @param expires_in [ActiveSupport::Duration, Integer] an expiry time for the cache entry
      # @param presenter_args [Hash] keyword arguments to be passed to the entity
      # @return [Gitlab::Json::PrecompiledJson]
      def present_cached(obj_or_collection, with:, cache_context: -> (_) { current_user&.cache_key }, expires_in: Gitlab::Cache::Helpers::DEFAULT_EXPIRY, **presenter_args)
        json =
          if obj_or_collection.is_a?(Enumerable)
            cached_collection(
              obj_or_collection,
              presenter: with,
              presenter_args: presenter_args,
              context: cache_context,
              expires_in: expires_in
            )
          else
            cached_object(
              obj_or_collection,
              presenter: with,
              presenter_args: presenter_args,
              context: cache_context,
              expires_in: expires_in
            )
          end

        body Gitlab::Json::PrecompiledJson.new(json)
      end

      # Action caching implementation
      #
      # This allows you to wrap an entire API endpoint call in a cache, useful
      # for short TTL caches to effectively rate-limit an endpoint. The block
      # will be converted to JSON and cached, and returns a
      # `Gitlab::Json::PrecompiledJson` object which will be exported without
      # secondary conversion.
      #
      # @param key [Object] any object that can be converted into a cache key
      # @param expires_in [ActiveSupport::Duration, Integer] an expiry time for the cache entry
      # @return [Gitlab::Json::PrecompiledJson]
      def cache_action(key, **cache_opts)
        json = cache.fetch(key, **apply_default_cache_options(cache_opts)) do
          response = yield

          if response.is_a?(Gitlab::Json::PrecompiledJson)
            response.to_s
          else
            Gitlab::Json.dump(response.as_json)
          end
        end

        body Gitlab::Json::PrecompiledJson.new(json)
      end

      # Conditionally cache an action
      #
      # Perform a `cache_action` only if the conditional passes
      def cache_action_if(conditional, *opts, **kwargs)
        if conditional
          cache_action(*opts, **kwargs) do
            yield
          end
        else
          yield
        end
      end

      # Conditionally cache an action
      #
      # Perform a `cache_action` unless the conditional passes
      def cache_action_unless(conditional, *opts, **kwargs)
        cache_action_if(!conditional, *opts, **kwargs) do
          yield
        end
      end

      private

      def apply_default_cache_options(opts = {})
        DEFAULT_CACHE_OPTIONS.merge(opts)
      end
    end
  end
end
