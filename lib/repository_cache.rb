# Interface to the Redis-backed cache store used by the Repository model
class RepositoryCache
  attr_reader :namespace, :backend

  def initialize(namespace, backend = Rails.cache)
    @namespace = namespace
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
