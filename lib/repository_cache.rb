# Interface to the Redis-backed cache store used by the Repository model
class RepositoryCache
  attr_reader :namespace, :backend, :project_id

  def initialize(namespace, project_id, backend = Rails.cache)
    @namespace = namespace
    @backend = backend
    @project_id = project_id
  end

  def cache_key(type)
    "#{type}:#{namespace}:#{project_id}"
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
