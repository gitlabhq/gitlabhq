require 'peek/adapters/redis'

Peek::Adapters::Redis.prepend ::Gitlab::PerformanceBar::RedisAdapterWhenPeekEnabled
Peek.singleton_class.prepend ::Gitlab::PerformanceBar::WithTopLevelWarnings

Rails.application.config.peek.adapter = :redis, { client: ::Redis.new(Gitlab::Redis::Cache.params) }

Peek.into Peek::Views::Host
Peek.into Peek::Views::ActiveRecord
Peek.into Peek::Views::Gitaly
Peek.into Peek::Views::RedisDetailed
Peek.into Peek::Views::Rugged

Peek.into Peek::Views::Tracing if Labkit::Tracing.tracing_url_enabled?
