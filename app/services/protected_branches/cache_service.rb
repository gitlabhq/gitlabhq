# frozen_string_literal: true

module ProtectedBranches
  class CacheService < ProtectedBranches::BaseService
    CACHE_ROOT_KEY = 'cache:gitlab:protected_branch'
    TTL_UNSET = -1
    CACHE_EXPIRE_IN = 1.day
    CACHE_LIMIT = 1000

    def fetch(ref_name, dry_run: false)
      record = OpenSSL::Digest::SHA256.hexdigest(ref_name)

      Gitlab::Redis::Cache.with do |redis|
        cached_result = redis.hget(redis_key, record)

        decoded_result = Gitlab::Redis::Boolean.decode(cached_result) unless cached_result.nil?

        # If we're dry-running, don't break because we need to check against
        # the real value to ensure the cache is working properly.
        # If the result is nil we'll need to run the block, so don't break yet.
        break decoded_result unless dry_run || decoded_result.nil?

        calculated_value = yield

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
      Gitlab::Redis::Cache.with { |redis| redis.unlink(redis_key) }
    end

    private

    def check_and_log_discrepancy(cached_value, real_value, ref_name)
      return if cached_value.nil?
      return if cached_value == real_value

      encoded_ref_name = Gitlab::EncodingHelper.encode_utf8_with_replacement_character(ref_name)

      log_error(
        'class' => self.class.name,
        'message' => "Cache mismatch '#{encoded_ref_name}': cached value: #{cached_value}, real value: #{real_value}",
        'project_id' => @project.id,
        'project_path' => @project.full_path
      )
    end

    def redis_key
      @redis_key ||= [CACHE_ROOT_KEY, @project.id].join(':')
    end
  end
end
