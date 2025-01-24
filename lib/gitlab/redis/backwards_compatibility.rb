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
            redis.pipelined do |pipeline|
              limit.times { pipeline.lpop(key) }
            end.compact
          end
        end
      end
    end
  end
end
