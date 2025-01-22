# frozen_string_literal: true

require 'gitlab/redis'

Redis.raise_deprecations = true unless Rails.env.production?

# rubocop:disable Gitlab/NoCodeCoverageComment
# :nocov: This snippet is for local development only, reloading in specs would raise NameError
if Rails.env.development?
  # reset all pools in the event of a reload
  # This makes sure that there are no stale references to classes in the `Gitlab::Redis` namespace
  # that also got reloaded.
  Gitlab::Application.config.to_prepare do
    Gitlab::Redis::ALL_CLASSES.each do |redis_instance|
      redis_instance.instance_variable_set(:@pool, nil)
    end

    Rails.cache = ActiveSupport::Cache::RedisCacheStore.new(**Gitlab::Redis::Cache.active_support_config)
  end
end
# :nocov:
# rubocop:enable Gitlab/NoCodeCoverageComment

# RedisClient instrumentation deadlocks with code reloading due to
# Prometheus metrics needing to check ApplicationSetting. Disable the
# instrumentation in that case. Code reloading should only be enabled in
# development.
if Rails.application.config.cache_classes || Rails.env.test?
  # this only instruments `RedisClient` used in `Sidekiq.redis`
  RedisClient.register(Gitlab::Instrumentation::RedisClientMiddleware)
  RedisClient.prepend(Gitlab::Patch::RedisClient)

  # This specifically instruments for Redis Cluster node failures.
  RedisClient::Cluster::Router.prepend(Gitlab::Instrumentation::RedisClusterRouter)
end

if Gitlab::Redis::Workhorse.params[:cluster].present?
  raise "Do not configure workhorse with a Redis Cluster as pub/sub commands are not cluster-compatible."
end

# Make sure we initialize a Redis connection pool before multi-threaded
# execution starts by
# 1. Sidekiq
# 2. Rails.cache
# 3. HTTP clients
Gitlab::Redis::ALL_CLASSES.each do |redis_instance|
  redis_instance.with { nil }
end
