# frozen_string_literal: true

module Gitlab
  module Redis
    module BackwardsCompatibility
      extend ActiveSupport::Concern

      class_methods do
        def lpop_with_limit(key, limit)
          Gitlab::Redis::SharedState.with do |redis|
            # To keep this compatible with Redis 6.0
            # use a Redis pipeline to pop all objects
            # instead of using lpop with limit.
            #
            # rubocop:disable Gitlab/FeatureFlagWithoutActor -- Does not execute with any actor in context
            # rubocop:disable Cop/FeatureFlagUsage -- Not a monkey patch or Redis code
            if Feature.enabled?(:toggle_redis_6_0_compatibility, type: :gitlab_com_derisk)
              redis.pipelined do |pipeline|
                limit.times { pipeline.lpop(key) }
              end.compact
            else
              redis.lpop(key, limit)
            end
            # rubocop:enable Gitlab/FeatureFlagWithoutActor
            # rubocop:enable Cop/FeatureFlagUsage
          end
        end
      end
    end
  end
end
