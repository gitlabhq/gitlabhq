# frozen_string_literal: true

require 'gitlab/redis'

Redis.raise_deprecations = true unless Rails.env.production?

Redis::Client.prepend(Gitlab::Instrumentation::RedisInterceptor)

# Make sure we initialize a Redis connection pool before multi-threaded
# execution starts by
# 1. Sidekiq
# 2. Rails.cache
# 3. HTTP clients
Gitlab::Redis::ALL_CLASSES.each do |redis_instance|
  redis_instance.with { nil }
end
