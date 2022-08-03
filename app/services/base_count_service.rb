# frozen_string_literal: true

# Base class for services that count a single resource such as the number of
# issues for a project.
class BaseCountService
  def relation_for_count
    raise(
      NotImplementedError,
      '"relation_for_count" must be implemented and return an ActiveRecord::Relation'
    )
  end

  def count
    Rails.cache.fetch(cache_key, cache_options) { uncached_count }.to_i
  end

  def count_stored?
    Rails.cache.read(cache_key).present?
  end

  def refresh_cache(&block)
    update_cache_for_key(cache_key, &block)
  end

  def uncached_count
    relation_for_count.count
  end

  def delete_cache
    ::Gitlab::Cache.delete(cache_key)
  end

  def raw?
    false
  end

  def cache_key
    raise NotImplementedError, 'cache_key must be implemented and return a String, Array, or Hash'
  end

  # subclasses can override to add any specific options, such as
  #   super.merge({ expires_in: 5.minutes })
  def cache_options
    { raw: raw? }
  end

  def update_cache_for_key(key, &block)
    Rails.cache.write(key, block ? yield : uncached_count, raw: raw?)
  end
end

BaseCountService.prepend_mod
