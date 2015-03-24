# rack-attack v4.2.0 doesn't yet support clearing of keys.
# Taken from https://github.com/kickstarter/rack-attack/issues/113
class Rack::Attack::Allow2Ban
  def self.reset(discriminator, options)
    findtime = options[:findtime] or raise ArgumentError, "Must pass findtime option"

    cache.reset_count("#{key_prefix}:count:#{discriminator}", findtime)
    cache.delete("#{key_prefix}:ban:#{discriminator}")
  end
end

class Rack::Attack::Cache
  def reset_count(unprefixed_key, period)
    epoch_time = Time.now.to_i
    # Add 1 to expires_in to avoid timing error: http://git.io/i1PHXA
    expires_in = period - (epoch_time % period) + 1
    key = "#{(epoch_time / period).to_i}:#{unprefixed_key}"
    delete(key)
  end

  def delete(unprefixed_key)
    store.delete("#{prefix}:#{unprefixed_key}")
  end
end

class Rack::Attack::StoreProxy::RedisStoreProxy
  def delete(key, options={})
    self.del(key)
    rescue Redis::BaseError
  end
end
