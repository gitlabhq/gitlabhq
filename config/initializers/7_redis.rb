# frozen_string_literal: true

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
