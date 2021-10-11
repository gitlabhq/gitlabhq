# frozen_string_literal: true
module Gitlab
  module MergeRequests
    module Mergeability
      class RedisInterface
        EXPIRATION = 6.hours
        VERSION = 1

        def save_check(merge_check:, result_hash:)
          Gitlab::Redis::SharedState.with do |redis|
            redis.set(merge_check.cache_key + ":#{VERSION}", result_hash.to_json, ex: EXPIRATION)
          end
        end

        def retrieve_check(merge_check:)
          Gitlab::Redis::SharedState.with do |redis|
            Gitlab::Json.parse(redis.get(merge_check.cache_key + ":#{VERSION}"))
          end
        end
      end
    end
  end
end
