# frozen_string_literal: true

module Gitlab
  module Cache
    module Helpers
      # @return [ActiveSupport::Duration]
      DEFAULT_EXPIRY = 1.day

      # @return [ActiveSupport::Cache::Store]
      def cache
        Rails.cache
      end

      def render_cached(obj_or_collection, with:, cache_context: -> (_) { current_user&.cache_key }, expires_in: Gitlab::Cache::Helpers::DEFAULT_EXPIRY, **presenter_args)
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

        render Gitlab::Json::PrecompiledJson.new(json)
      end

      private

      # Optionally uses a `Proc` to add context to a cache key
      #
      # @param object [Object] must respond to #cache_key
      # @param context [Proc] a proc that will be called with the object as an argument, and which should return a
      #                       string or array of strings to be combined into the cache key
      # @return [String]
      def contextual_cache_key(presenter, object, context)
        return object.cache_key if context.nil?

        [presenter.class.name, object.cache_key, context.call(object)].flatten.join(":")
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
        cache.fetch(contextual_cache_key(presenter, object, context), expires_in: expires_in) do
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
        json = fetch_multi(presenter, collection, context: context, expires_in: expires_in) do |obj|
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
      def fetch_multi(presenter, *objs, context:, **kwargs)
        objs.flatten!
        map = multi_key_map(presenter, objs, context: context)

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
      def multi_key_map(presenter, objects, context:)
        objects.index_by do |object|
          contextual_cache_key(presenter, object, context)
        end
      end
    end
  end
end
