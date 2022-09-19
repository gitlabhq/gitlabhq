# frozen_string_literal: true

require 'gitlab/redis'

Redis.raise_deprecations = true unless Rails.env.production?

# We set the instance variable directly to suppress warnings.
# We cannot switch to the new behavior until we change all existing `redis.exists` calls to `redis.exists?`.
# Some gems also need to be updated
# https://gitlab.com/gitlab-org/gitlab/-/issues/340602
Redis.instance_variable_set(:@exists_returns_integer, false)

Redis::Client.prepend(Gitlab::Instrumentation::RedisInterceptor)

# Make sure we initialize a Redis connection pool before multi-threaded
# execution starts by
# 1. Sidekiq
# 2. Rails.cache
# 3. HTTP clients
Gitlab::Redis::ALL_CLASSES.each do |redis_instance|
  redis_instance.with { nil }
end
