# frozen_string_literal: true

module ProtectedBranches
  class CacheService < ProtectedBranches::BaseService
    CACHE_ROOT_KEY = 'cache:gitlab:protected_branch'
    TTL_UNSET = -1
    CACHE_EXPIRE_IN = 1.day
    CACHE_LIMIT = 1000

    def fetch(ref_name, dry_run: false, &block)
      record = OpenSSL::Digest::SHA256.hexdigest(ref_name)

      with_redis do |redis|
        cached_result = redis.hget(redis_key, record)

        if cached_result.nil?
          metrics.increment_cache_miss
        else
          metrics.increment_cache_hit

          decoded_result = Gitlab::Redis::Boolean.decode(cached_result)
        end

        # If we're dry-running, don't break because we need to check against
        # the real value to ensure the cache is working properly.
        # If the result is nil we'll need to run the block, so don't break yet.
        break decoded_result unless dry_run || decoded_result.nil?

        calculated_value = metrics.observe_cache_generation(&block)

        check_and_log_discrepancy(decoded_result, calculated_value, ref_name) if dry_run

        redis.hset(redis_key, record, Gitlab::Redis::Boolean.encode(calculated_value))

        # We don't want to extend cache expiration time
        if redis.ttl(redis_key) == TTL_UNSET
          redis.expire(redis_key, CACHE_EXPIRE_IN)
        end

        # If the cache record has too many elements, then something went wrong and
        # it's better to drop the cache key.
        if redis.hlen(redis_key) > CACHE_LIMIT
          redis.unlink(redis_key)
        end

        calculated_value
      end
    end

    def refresh
      with_redis { |redis| redis.unlink(redis_key) }
    end

    private

    def with_redis(&block)
      Gitlab::Redis::Cache.with(&block) # rubocop:disable CodeReuse/ActiveRecord
    end

    def check_and_log_discrepancy(cached_value, real_value, ref_name)
      return if cached_value.nil?
      return if cached_value == real_value

      encoded_ref_name = Gitlab::EncodingHelper.encode_utf8_with_replacement_character(ref_name)

      log_error(
        'class' => self.class.name,
        'message' => "Cache mismatch '#{encoded_ref_name}': cached value: #{cached_value}, real value: #{real_value}",
        'record_class' => project_or_group.class.name,
        'record_id' => project_or_group.id,
        'record_path' => project_or_group.full_path
      )
    end

    def redis_key
      group = project_or_group.is_a?(Group) ? project_or_group : project_or_group.group
      @redis_key ||= if allow_protected_branches_for_group?(group)
                       [CACHE_ROOT_KEY, project_or_group.class.name, project_or_group.id].join(':')
                     else
                       [CACHE_ROOT_KEY, project_or_group.id].join(':')
                     end
    end

    def allow_protected_branches_for_group?(group)
      Feature.enabled?(:group_protected_branches, group) ||
        Feature.enabled?(:allow_protected_branches_for_group, group)
    end

    def metrics
      @metrics ||= Gitlab::Cache::Metrics.new(cache_metadata)
    end

    def cache_metadata
      Gitlab::Cache::Metadata.new(
        cache_identifier: "#{self.class}#fetch",
        feature_category: :source_code_management,
        backing_resource: :cpu
      )
    end
  end
end
