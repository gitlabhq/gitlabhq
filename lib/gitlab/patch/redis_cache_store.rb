# frozen_string_literal: true

module Gitlab
  module Patch
    module RedisCacheStore
      PATCH_INPUT_LIMIT = 100
      PIPELINE_BATCH_SIZE = 100

      # We will try keep patched code explicit and matching the original signature in
      # https://github.com/rails/rails/blob/v6.1.7.2/activesupport/lib/active_support/cache/redis_cache_store.rb#L361
      def read_multi_mget(*names) # rubocop:disable Style/ArgumentsForwarding
        return super unless enable_rails_cache_pipeline_patch?
        return super if names.size > PATCH_INPUT_LIMIT # avoid excessive apdex degradation during benchmarking exercise

        patched_read_multi_mget(*names) # rubocop:disable Style/ArgumentsForwarding
      end

      # `delete_multi_entries` in Rails runs a multi-key `del` command
      # patch will run pipelined single-key `del` for Redis Cluster compatibility
      def delete_multi_entries(entries, **options)
        return super unless enable_rails_cache_pipeline_patch?

        delete_count = 0
        redis.with do |conn|
          entries.each_slice(PIPELINE_BATCH_SIZE) do |subset|
            delete_count += conn.pipelined do |pipeline|
              subset.each { |entry| pipeline.del(entry) }
            end.sum
          end
        end
        delete_count
      end

      # Copied from https://github.com/rails/rails/blob/v6.1.6.1/activesupport/lib/active_support/cache/redis_cache_store.rb
      # re-implements `read_multi_mget` using a pipeline of `get`s rather than an `mget`
      #
      def patched_read_multi_mget(*names)
        options = names.extract_options!
        options = merged_options(options)
        return {} if names == []

        raw = options&.fetch(:raw, false)

        keys = names.map { |name| normalize_key(name, options) }

        values = failsafe(:patched_read_multi_mget, returning: {}) do
          redis.with { |c| pipeline_mget(c, keys) }
        end

        names.zip(values).each_with_object({}) do |(name, value), results|
          if value # rubocop:disable Style/Next
            entry = deserialize_entry(value, raw: raw)
            unless entry.nil? || entry.expired? || entry.mismatched?(normalize_version(name, options))
              results[name] = entry.value
            end
          end
        end
      end

      def pipeline_mget(conn, keys)
        conn.pipelined do |p|
          keys.each { |key| p.get(key) }
        end
      end

      private

      def enable_rails_cache_pipeline_patch?
        redis_cache? &&
          Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands? &&
          ::Feature.enabled?(:enable_rails_cache_pipeline_patch) # rubocop:disable Cop/FeatureFlagUsage
      end

      def redis_cache?
        # We do not want to risk cycles of feature code calling redis calling feature code.
        # Also, we only want to benchmark redis-cache, hence repository-cache and rate-limiting are excluded.
        !is_a?(Gitlab::Redis::FeatureFlag::FeatureFlagStore) &&
          !is_a?(Gitlab::Redis::RepositoryCache::RepositoryCacheStore) &&
          !is_a?(Gitlab::Redis::RateLimiting::RateLimitingStore)
      end
    end
  end
end
