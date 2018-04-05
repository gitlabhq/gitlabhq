module Gitlab
  module RepositoryCacheAdapter
    extend ActiveSupport::Concern

    class_methods do
      # Wraps around the given method and caches its output in Redis and an instance
      # variable.
      #
      # This only works for methods that do not take any arguments.
      def cache_method(name, fallback: nil, memoize_only: false)
        original = :"_uncached_#{name}"

        alias_method(original, name)

        define_method(name) do
          cache_method_output(name, fallback: fallback, memoize_only: memoize_only) do
            __send__(original) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end
    end

    # RepositoryCache to be used. Should be overridden by the including class
    def cache
      raise NotImplementedError
    end

    # Caches the supplied block both in a cache and in an instance variable.
    #
    # The cache key and instance variable are named the same way as the value of
    # the `key` argument.
    #
    # This method will return `nil` if the corresponding instance variable is also
    # set to `nil`. This ensures we don't keep yielding the block when it returns
    # `nil`.
    #
    # key - The name of the key to cache the data in.
    # fallback - A value to fall back to in the event of a Git error.
    def cache_method_output(key, fallback: nil, memoize_only: false, &block)
      ivar = cache_instance_variable_name(key)

      if instance_variable_defined?(ivar)
        instance_variable_get(ivar)
      else
        # If the repository doesn't exist and a fallback was specified we return
        # that value inmediately. This saves us Rugged/gRPC invocations.
        return fallback unless fallback.nil? || cache.repository.exists?

        begin
          value =
            if memoize_only
              yield
            else
              cache.fetch(key, &block)
            end

          instance_variable_set(ivar, value)
        rescue Gitlab::Git::Repository::NoRepository
          # Even if the above `#exists?` check passes these errors might still
          # occur (for example because of a non-existing HEAD). We want to
          # gracefully handle this and not cache anything
          fallback
        end
      end
    end

    # Expires the caches of a specific set of methods
    def expire_method_caches(methods)
      methods.each do |key|
        cache.expire(key)

        ivar = cache_instance_variable_name(key)

        remove_instance_variable(ivar) if instance_variable_defined?(ivar)
      end
    end

    private

    def cache_instance_variable_name(key)
      :"@#{key.to_s.tr('?!', '')}"
    end
  end
end
