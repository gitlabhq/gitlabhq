# Concern for caching method into instance variable and redis cache
module CacheMethod
  extend ActiveSupport::Concern

  module ClassMethods
    # Wraps around the given method and caches its output in Redis and an instance
    # variable.
    #
    # This only works for methods that do not take any arguments.
    def cache_method(name)
      original = :"_uncached_#{name}"

      alias_method(original, name)

      define_method(name) do
        cache_method_output(name) { __send__(original) }
      end
    end
  end

  # Expires the caches of a specific set of methods
  def expire_method_caches(methods)
    methods.each do |key|
      cache.delete(cache_key(key))

      ivar = cache_instance_variable_name(key)

      remove_instance_variable(ivar) if instance_variable_defined?(ivar)
    end
  end

  private

  # Caches the supplied block both in a cache and in an instance variable.
  #
  # The cache key and instance variable are named the same way as the value of
  # the `key` argument.
  #
  # This method will return `nil` if the corresponding instance variable is also
  # set to `nil`. This ensures we don't keep yielding the block when it returns
  # `nil`.
  #
  # name - The name of the key to cache the data in.
  def cache_method_output(name, &block)
    ivar = cache_instance_variable_name(name)

    if instance_variable_defined?(ivar)
      instance_variable_get(ivar)
    else
      instance_variable_set(ivar, cache.fetch(cache_key(name), &block))
    end
  end

  def cache_instance_variable_name(key)
    :"@#{key.to_s.tr('?!', '')}"
  end

  def cache
    @cache ||= Rails.cache
  end

  def cache_key(key)
    "#{self.class.name.tableize}:#{id}:#{key}"
  end
end
