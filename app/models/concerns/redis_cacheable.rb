module RedisCacheable
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  CACHED_ATTRIBUTES_EXPIRY_TIME = 24.hours

  class_methods do
    def cached_attr_reader(*attributes)
      attributes.each do |attribute|
        define_method("#{attribute}") do
          cached_attribute(attribute) || read_attribute(attribute)
        end
      end
    end
  end

  def cached_attribute(attribute)
    (cached_attributes || {})[attribute]
  end

  def cache_attributes(values)
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(cache_attribute_key, values.to_json, ex: CACHED_ATTRIBUTES_EXPIRY_TIME)
    end
  end

  private

  def cache_attribute_key
    "cache:#{self.class.name}:#{self.id}:attributes"
  end

  def cached_attributes
    strong_memoize(:cached_attributes) do
      Gitlab::Redis::SharedState.with do |redis|
        data = redis.get(cache_attribute_key)
        JSON.parse(data, symbolize_names: true) if data
      end
    end
  end
end
