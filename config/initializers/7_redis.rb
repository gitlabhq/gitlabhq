# Make sure we initialize a Redis connection pool before Sidekiq starts
# multi-threaded execution.
Gitlab::Redis.with { nil }
