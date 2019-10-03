# frozen_string_literal: true

module Gitlab
  module HealthChecks
    CHECKS = [
      Gitlab::HealthChecks::DbCheck,
      Gitlab::HealthChecks::Redis::RedisCheck,
      Gitlab::HealthChecks::Redis::CacheCheck,
      Gitlab::HealthChecks::Redis::QueuesCheck,
      Gitlab::HealthChecks::Redis::SharedStateCheck,
      Gitlab::HealthChecks::GitalyCheck
    ].freeze
  end
end
