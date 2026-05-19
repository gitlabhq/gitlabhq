# frozen_string_literal: true

module Gitlab
  module MergeRequests
    module Mergeability
      class RedisInterface
        VERSION = 1

        def save_check(merge_check:, result_hash:, ttl:)
          with_redis do |redis|
            redis.set(merge_check.cache_key + ":#{VERSION}", result_hash.to_json, ex: ttl)
          end
        end

        def retrieve_check(merge_check:)
          with_redis do |redis|
            Gitlab::Json.parse(redis.get(merge_check.cache_key + ":#{VERSION}"), symbolize_keys: true)
          end
        end

        def delete_check(cache_key:)
          with_redis do |redis|
            redis.del(cache_key + ":#{VERSION}")
          end
        end

        def with_redis(&block)
          Gitlab::Redis::Cache.with(&block) # rubocop:disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
