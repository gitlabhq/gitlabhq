# frozen_string_literal: true

# Interface to the Redis-backed cache store
module Gitlab
  class RepositoryCache
    attr_reader :repository, :namespace, :backend

    def initialize(repository, extra_namespace: nil, backend: self.class.store)
      @repository = repository
      @namespace = repository.full_path.to_s
      @namespace += ":#{repository.project.id}" if repository.project
      @namespace = "#{@namespace}:#{extra_namespace}" if extra_namespace
      @backend = backend
    end

    def cache_key(type)
      "#{type}:#{namespace}"
    end

    def expire(key)
      backend.delete(cache_key(key))
    end

    def fetch(key, &block)
      backend.fetch(cache_key(key), &block)
    end

    def exist?(key)
      backend.exist?(cache_key(key))
    end

    def read(key)
      backend.read(cache_key(key))
    end

    def write(key, value, *args)
      backend.write(cache_key(key), value, *args)
    end

    def fetch_without_caching_false(key, &block)
      value = read(key)
      return value if value

      value = yield

      # Don't cache false values
      write(key, value) if value

      value
    end

    def self.store
      Gitlab::Redis::RepositoryCache.cache_store
    end
  end
end
