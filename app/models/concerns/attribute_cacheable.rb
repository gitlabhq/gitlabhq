module AttributeCacheable
  extend ActiveSupport::Concern

  class_methods do
    def redis_cached_attributes(*attributes)
      attributes.each do |attribute|
        define_method("#{attribute}") do
          cached_attribute(attribute) || read_attribute(attribute)
        end
      end
    end
  end

  def cached_attribute(key)
    Gitlab::Redis::SharedState.with do |redis|
      redis.get(cache_attribute_key(key))
    end
  end

  def cache_attributes(values)
    Gitlab::Redis::SharedState.with do |redis|
      values.each do |key, value|
        redis.set(cache_attribute_key(key), value, ex: 24.hours)
      end
    end
  end

  private

  def cache_attribute_key(key)
    "#{self.class.name}:attributes:#{self.id}:#{key}"
  end
end
