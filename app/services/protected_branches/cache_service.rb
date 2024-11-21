# frozen_string_literal: true

module ProtectedBranches
  class CacheService < ProtectedBranches::BaseService
    include Gitlab::Utils::StrongMemoize

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

      return unless (group = project_or_group).is_a?(Group)

      group.all_projects.each_batch do |projects_relation|
        # First we remove the cache for each project in the group and then
        # touch the projects_relation to update the projects' cache key.
        with_redis do |redis|
          projects_relation.each do |project|
            redis.unlink redis_key(project)
          end
        end
        projects_relation.touch_all
      end
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

    def redis_key(entity = project_or_group)
      strong_memoize_with(:redis_key, entity) do
        ProtectedBranch::CacheKey.new(entity).to_s
      end
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
