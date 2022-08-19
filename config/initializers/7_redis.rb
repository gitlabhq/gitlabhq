# frozen_string_literal: true

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
Gitlab::Redis::Cache.with { nil }
Gitlab::Redis::Queues.with { nil }
Gitlab::Redis::SharedState.with { nil }
Gitlab::Redis::TraceChunks.with { nil }
Gitlab::Redis::RateLimiting.with { nil }
Gitlab::Redis::Sessions.with { nil }
Gitlab::Redis::DuplicateJobs.with { nil }
Gitlab::Redis::SidekiqStatus.with { nil }
