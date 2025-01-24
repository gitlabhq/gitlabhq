# frozen_string_literal: true

module Gitlab
  module Redis
    # List all Gitlab::Redis::Wrapper descendants that are backed by an actual
    # separate redis instance here.
    #
    # This will make sure the connection pool is initialized on application boot in
    # config/initializers/7_redis.rb, instrumented, and used in health- & readiness checks.
    ALL_CLASSES = [
      Gitlab::Redis::BufferedCounter,
      Gitlab::Redis::Cache,
      Gitlab::Redis::ClusterSessions,
      Gitlab::Redis::DbLoadBalancing,
      Gitlab::Redis::FeatureFlag,
      *Gitlab::Redis::Queues.instances.values, # dynamically adds QueueShard* classes
      Gitlab::Redis::QueuesMetadata,
      Gitlab::Redis::RateLimiting,
      Gitlab::Redis::RepositoryCache,
      Gitlab::Redis::Sessions,
      Gitlab::Redis::SharedState,
      Gitlab::Redis::TraceChunks,
      Gitlab::Redis::Chat,
      Gitlab::Redis::Workhorse
    ].freeze
  end
end
