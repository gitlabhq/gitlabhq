# frozen_string_literal: true
module Gitlab
  module MergeRequests
    module Mergeability
      class RedisInterface
        EXPIRATION = 6.hours
        VERSION = 1

        def save_check(merge_check:, result_hash:)
          with_redis do |redis|
            redis.set(merge_check.cache_key + ":#{VERSION}", result_hash.to_json, ex: EXPIRATION)
          end
        end

        def retrieve_check(merge_check:)
          with_redis do |redis|
            Gitlab::Json.parse(redis.get(merge_check.cache_key + ":#{VERSION}"), symbolize_keys: true)
          end
        end

        def with_redis(&block)
          Gitlab::Redis::Cache.with(&block) # rubocop:disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
