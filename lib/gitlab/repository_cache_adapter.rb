# frozen_string_literal: true

module Gitlab
  module RepositoryCacheAdapter
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    class_methods do
      # Caches and strongly memoizes the method.
      #
      # This only works for methods that do not take any arguments.
      #
      # name     - The name of the method to be cached.
      # fallback - A value to fall back to if the repository does not exist, or
      #            in case of a Git error. Defaults to nil.
      def cache_method(name, fallback: nil)
        uncached_name = alias_uncached_method(name)

        define_method(name) do
          cache_method_output(name, fallback: fallback) do
            __send__(uncached_name) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end

      # Caches and strongly memoizes the method as a Redis Set.
      #
      # This only works for methods that do not take any arguments. The method
      # should return an Array of Strings to be cached.
      #
      # In addition to overriding the named method, a "name_include?" method is
      # defined. This uses the "SISMEMBER" query to efficiently check membership
      # without needing to load the entire set into memory.
      #
      # name     - The name of the method to be cached.
      # fallback - A value to fall back to if the repository does not exist, or
      #            in case of a Git error. Defaults to nil.
      #
      # It is not safe to use this method prior to the release of 12.3, since
      # 12.2 does not correctly invalidate the redis set cache value. A mixed
      # code environment containing both 12.2 and 12.3 nodes breaks, while a
      # mixed code environment containing both 12.3 and 12.4 nodes will work.
      def cache_method_as_redis_set(name, fallback: nil)
        uncached_name = alias_uncached_method(name)

        define_method(name) do
          cache_method_output_as_redis_set(name, fallback: fallback) do
            __send__(uncached_name) # rubocop:disable GitlabSecurity/PublicSend
          end
        end

        # Attempt to determine whether a value is in the set of values being
        # cached, by performing a redis SISMEMBERS query if appropriate.
        #
        # If the full list is already in-memory, we're better using it directly.
        #
        # If the cache is not yet populated, querying it directly will give the
        # wrong answer. We handle that by querying the full list - which fills
        # the cache - and using it directly to answer the question.
        define_method("#{name}_include?") do |value|
          ivar = "@#{name}_include"
          memoized = instance_variable_get(ivar) || {}
          lookup = proc { __send__(name).include?(value) } # rubocop:disable GitlabSecurity/PublicSend

          next memoized[value] if memoized.key?(value)

          memoized[value] =
            if strong_memoized?(name)
              lookup.call
            else
              result, exists = redis_set_cache.try_include?(name, value)

              exists ? result : lookup.call
            end

          instance_variable_set(ivar, memoized)[value]
        end
      end

      # Caches truthy values from the method. All values are strongly memoized,
      # and cached in RequestStore.
      #
      # Currently only used to cache `exists?` since stale false values are
      # particularly troublesome. This can occur, for example, when an NFS mount
      # is temporarily down.
      #
      # This only works for methods that do not take any arguments.
      #
      # name - The name of the method to be cached.
      def cache_method_asymmetrically(name)
        uncached_name = alias_uncached_method(name)

        define_method(name) do
          cache_method_output_asymmetrically(name) do
            __send__(uncached_name) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end

      # Strongly memoizes the method.
      #
      # This only works for methods that do not take any arguments.
      #
      # name     - The name of the method to be memoized.
      # fallback - A value to fall back to if the repository does not exist, or
      #            in case of a Git error. Defaults to nil. The fallback value
      #            is not memoized.
      def memoize_method(name, fallback: nil)
        uncached_name = alias_uncached_method(name)

        define_method(name) do
          memoize_method_output(name, fallback: fallback) do
            __send__(uncached_name) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end

      # Prepends "_uncached_" to the target method name
      #
      # Returns the uncached method name
      def alias_uncached_method(name)
        uncached_name = :"_uncached_#{name}"

        alias_method(uncached_name, name)

        uncached_name
      end
    end

    # RequestStore-backed RepositoryCache to be used. Should be overridden by
    # the including class
    def request_store_cache
      raise NotImplementedError
    end

    # RepositoryCache to be used. Should be overridden by the including class
    def cache
      raise NotImplementedError
    end

    # RepositorySetCache to be used. Should be overridden by the including class
    def redis_set_cache
      raise NotImplementedError
    end

    # RepositoryHashCache to be used. Should be overridden by the including class
    def redis_hash_cache
      raise NotImplementedError
    end

    # List of cached methods. Should be overridden by the including class
    def cached_methods
      raise NotImplementedError
    end

    # Caches and strongly memoizes the supplied block.
    #
    # name     - The name of the method to be cached.
    # fallback - A value to fall back to if the repository does not exist, or
    #            in case of a Git error. Defaults to nil.
    def cache_method_output(name, fallback: nil, &block)
      memoize_method_output(name, fallback: fallback) do
        cache.fetch(name, &block)
      end
    end

    # Caches and strongly memoizes the supplied block as a Redis Set. The result
    # will be provided as a sorted array.
    #
    # name     - The name of the method to be cached.
    # fallback - A value to fall back to if the repository does not exist, or
    #            in case of a Git error. Defaults to nil.
    def cache_method_output_as_redis_set(name, fallback: nil, &block)
      memoize_method_output(name, fallback: fallback) do
        redis_set_cache.fetch(name, &block).sort
      end
    end

    # Caches truthy values from the supplied block. All values are strongly
    # memoized, and cached in RequestStore.
    #
    # Currently only used to cache `exists?` since stale false values are
    # particularly troublesome. This can occur, for example, when an NFS mount
    # is temporarily down.
    #
    # name - The name of the method to be cached.
    def cache_method_output_asymmetrically(name, &block)
      memoize_method_output(name) do
        request_store_cache.fetch(name) do
          cache.fetch_without_caching_false(name, &block)
        end
      end
    end

    # Strongly memoizes the supplied block.
    #
    # name     - The name of the method to be memoized.
    # fallback - A value to fall back to if the repository does not exist, or
    #            in case of a Git error. Defaults to nil. The fallback value is
    #            not memoized.
    def memoize_method_output(name, fallback: nil, &block)
      no_repository_fallback(name, fallback: fallback) do
        strong_memoize(memoizable_name(name), &block)
      end
    end

    # Returns the fallback value if the repository does not exist
    def no_repository_fallback(name, fallback: nil, &block)
      # Avoid unnecessary gRPC invocations
      return fallback if fallback && fallback_early?(name)

      yield
    rescue Gitlab::Git::Repository::NoRepository
      # Even if the `#exists?` check in `fallback_early?` passes, these errors
      # might still occur (for example because of a non-existing HEAD). We
      # want to gracefully handle this and not memoize anything.
      fallback
    end

    def memoize_method_cache_value(method, value)
      strong_memoize(memoizable_name(method)) { value }
    end

    # Expires the caches of a specific set of methods
    def expire_method_caches(methods)
      methods.each do |name|
        unless cached_methods.include?(name.to_sym)
          Gitlab::AppLogger.error "Requested to expire non-existent method '#{name}' for Repository"
          next
        end

        cache.expire(name)

        clear_memoization(memoizable_name(name))
      end

      expire_redis_set_method_caches(methods)
      expire_redis_hash_method_caches(methods)
      expire_request_store_method_caches(methods)
    end

    private

    def memoizable_name(name)
      name.to_s.tr('?!', '').to_s
    end

    def expire_request_store_method_caches(methods)
      methods.each do |name|
        request_store_cache.expire(name)
      end
    end

    def expire_redis_set_method_caches(methods)
      redis_set_cache.expire(*methods)
    end

    def expire_redis_hash_method_caches(methods)
      redis_hash_cache.delete(*methods)
    end

    # All cached repository methods depend on the existence of a Git repository,
    # so if the repository doesn't exist, we already know not to call it.
    def fallback_early?(method_name)
      # Avoid infinite loop
      return false if method_name == :exists?

      !exists?
    end
  end
end
