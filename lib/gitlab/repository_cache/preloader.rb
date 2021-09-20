# frozen_string_literal: true

module Gitlab
  class RepositoryCache
    class Preloader
      def initialize(repositories)
        @repositories = repositories
      end

      def preload(methods)
        return if @repositories.empty?

        cache_keys = []

        sources_by_cache_key = @repositories.each_with_object({}) do |repository, hash|
          methods.each do |method|
            cache_key = repository.cache.cache_key(method)

            hash[cache_key] = { repository: repository, method: method }
            cache_keys << cache_key
          end
        end

        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          backend.read_multi(*cache_keys).each do |cache_key, value|
            source = sources_by_cache_key[cache_key]

            source[:repository].memoize_method_cache_value(source[:method], value)
          end
        end
      end

      private

      def backend
        @repositories.first.cache.backend
      end
    end
  end
end
