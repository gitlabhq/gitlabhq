# frozen_string_literal: true

# Grape helpers for caching.
#
# This module helps introduce standardised caching into the Grape API
# in a similar manner to the standard Grape DSL.

module API
  module Helpers
    module Caching
      # @return [ActiveSupport::Duration]
      DEFAULT_EXPIRY = 1.day

      # @return [Hash]
      DEFAULT_CACHE_OPTIONS = {
        race_condition_ttl: 5.seconds
      }.freeze

      # @return [ActiveSupport::Cache::Store]
      def cache
        Rails.cache
      end

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
      def present_cached(obj_or_collection, with:, cache_context: -> (_) { current_user&.cache_key }, expires_in: DEFAULT_EXPIRY, **presenter_args)
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

      # Optionally uses a `Proc` to add context to a cache key
      #
      # @param object [Object] must respond to #cache_key
      # @param context [Proc] a proc that will be called with the object as an argument, and which should return a
      #                       string or array of strings to be combined into the cache key
      # @return [String]
      def contextual_cache_key(object, context)
        return object.cache_key if context.nil?

        [object.cache_key, context.call(object)].flatten.join(":")
      end

      # Used for fetching or rendering a single object
      #
      # @param object [Object] the object to render
      # @param presenter [Grape::Entity]
      # @param presenter_args [Hash] keyword arguments to be passed to the entity
      # @param context [Proc]
      # @param expires_in [ActiveSupport::Duration, Integer] an expiry time for the cache entry
      # @return [String]
      def cached_object(object, presenter:, presenter_args:, context:, expires_in:)
        cache.fetch(contextual_cache_key(object, context), expires_in: expires_in) do
          Gitlab::Json.dump(presenter.represent(object, **presenter_args).as_json)
        end
      end

      # Used for fetching or rendering multiple objects
      #
      # @param objects [Enumerable<Object>] the objects to render
      # @param presenter [Grape::Entity]
      # @param presenter_args [Hash] keyword arguments to be passed to the entity
      # @param context [Proc]
      # @param expires_in [ActiveSupport::Duration, Integer] an expiry time for the cache entry
      # @return [Array<String>]
      def cached_collection(collection, presenter:, presenter_args:, context:, expires_in:)
        json = fetch_multi(collection, context: context, expires_in: expires_in) do |obj|
          Gitlab::Json.dump(presenter.represent(obj, **presenter_args).as_json)
        end

        json.values
      end

      # An adapted version of ActiveSupport::Cache::Store#fetch_multi.
      #
      # The original method only provides the missing key to the block,
      # not the missing object, so we have to create a map of cache keys
      # to the objects to allow us to pass the object to the missing value
      # block.
      #
      # The result is that this is functionally identical to `#fetch`.
      def fetch_multi(*objs, context:, **kwargs)
        objs.flatten!
        map = multi_key_map(objs, context: context)

        # TODO: `contextual_cache_key` should be constructed based on the guideline https://docs.gitlab.com/ee/development/redis.html#multi-key-commands.
        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          cache.fetch_multi(*map.keys, **kwargs) do |key|
            yield map[key]
          end
        end
      end

      # @param objects [Enumerable<Object>] objects which _must_ respond to `#cache_key`
      # @param context [Proc] a proc that can be called to help generate each cache key
      # @return [Hash]
      def multi_key_map(objects, context:)
        objects.index_by do |object|
          contextual_cache_key(object, context)
        end
      end
    end
  end
end
