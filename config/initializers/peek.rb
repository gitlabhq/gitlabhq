require 'peek/adapters/redis'

Peek::Adapters::Redis.prepend ::Gitlab::PerformanceBar::RedisAdapterWhenPeekEnabled

Rails.application.config.peek.adapter = :redis, { client: ::Redis.new(Gitlab::Redis::Cache.params) }

Peek.into Peek::Views::Host
Peek.into Peek::Views::ActiveRecord
Peek.into Peek::Views::Gitaly
Peek.into Peek::Views::RedisDetailed
Peek.into Peek::Views::Rugged

# `Peek::Views::GC` is currently disabled in production, as it runs with every request
# even if PerformanceBar is inactive and clears `GC::Profiler` reports we need for metrics.
# Check https://gitlab.com/gitlab-org/gitlab-ce/issues/65455
Peek.into Peek::Views::GC if Rails.env.development?

Peek.into Peek::Views::Tracing if Labkit::Tracing.tracing_url_enabled?
