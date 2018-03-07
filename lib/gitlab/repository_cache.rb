# Interface to the Redis-backed cache store
module Gitlab
  class RepositoryCache
    attr_reader :repository, :namespace, :backend

    def initialize(repository, backend = Rails.cache)
      @repository = repository
      @namespace = "#{repository.full_path}:#{repository.project.id}"
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
  end
end
