# frozen_string_literal: true

module RedisCacheable
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  CACHED_ATTRIBUTES_EXPIRY_TIME = 24.hours

  class_methods do
    def cached_attr_reader(*attributes)
      attributes.each do |attribute|
        define_method(attribute) do
          unless self.has_attribute?(attribute)
            raise ArgumentError, "`cached_attr_reader` requires the #{self.class.name}\##{attribute} attribute to have a database column"
          end

          cached_attribute(attribute) || read_attribute(attribute)
        end
      end
    end
  end

  def cached_attribute(attribute)
    cached_value = (cached_attributes || {})[attribute]
    cast_value_from_cache(attribute, cached_value) if cached_value
  end

  def cache_attributes(values)
    Gitlab::Redis::Cache.with do |redis|
      redis.set(cache_attribute_key, values.to_json, ex: CACHED_ATTRIBUTES_EXPIRY_TIME)
    end

    clear_memoization(:cached_attributes)
  end

  private

  def cache_attribute_key
    "cache:#{self.class.name}:#{self.id}:attributes"
  end

  def cached_attributes
    strong_memoize(:cached_attributes) do
      Gitlab::Redis::Cache.with do |redis|
        data = redis.get(cache_attribute_key)
        Gitlab::Json.parse(data, symbolize_names: true) if data
      end
    end
  end

  def cast_value_from_cache(attribute, value)
    self.class.type_for_attribute(attribute.to_s).cast(value)
  end
end
