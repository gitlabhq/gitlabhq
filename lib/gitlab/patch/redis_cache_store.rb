# frozen_string_literal: true

module Gitlab
  module Patch
    module RedisCacheStore
      # We will try keep patched code explicit and matching the original signature in
      # https://github.com/rails/rails/blob/v7.1.3.4/activesupport/lib/active_support/cache/redis_cache_store.rb#L324
      def read_multi_entries(...)
        return super unless enable_rails_cache_pipeline_patch?
        return super unless use_patched_mget?

        patched_read_multi_entries(...)
      end

      # `delete_multi_entries` in Rails runs a multi-key `del` command
      # patch will run pipelined single-key `del` for Redis Cluster compatibility
      def delete_multi_entries(entries, **options)
        return super unless enable_rails_cache_pipeline_patch?

        redis.with do |conn|
          ::Gitlab::Redis::ClusterUtil.batch_del(entries, conn)
        end
      end

      # `pipeline_entries` is used by Rails for multi-key writes
      # patch will run pipelined single-key for Redis Cluster compatibility
      def pipeline_entries(entries, &block)
        return super unless enable_rails_cache_pipeline_patch?

        redis.with do |conn|
          ::Gitlab::Redis::ClusterUtil.batch(entries, conn, &block)
        end
      end

      # Copied from https://github.com/rails/rails/blob/v7.1.3.4/activesupport/lib/active_support/cache/redis_cache_store.rb#L324
      # re-implements `read_multi_entries` using a pipeline of `get`s rather than an `mget`
      def patched_read_multi_entries(names, **options)
        options = merged_options(options)
        return {} if names == []

        raw = options&.fetch(:raw, false)

        keys = names.map { |name| normalize_key(name, options) }

        values = failsafe(:patched_read_multi_entries, returning: {}) do
          redis.with do |c|
            ::Gitlab::Redis::ClusterUtil.batch_get(keys, c)
          end
        end

        names.zip(values).each_with_object({}) do |(name, value), results|
          next unless value

          entry = deserialize_entry(value, raw: raw)
          unless entry.nil? || entry.expired? || entry.mismatched?(normalize_version(name, options))
            results[name] = entry.value
          end
        end
      end

      private

      def enable_rails_cache_pipeline_patch?
        redis.with { |c| ::Gitlab::Redis::ClusterUtil.cluster?(c) }
      end

      # MultiStore reads ONLY from the default store (no fallback), hence we can use `mget`
      # if the default store is not a Redis::Cluster. We should do that as pipelining gets on a single redis is slow
      def use_patched_mget?
        redis.with do |conn|
          next true unless conn.is_a?(Gitlab::Redis::MultiStore)

          ::Gitlab::Redis::ClusterUtil.cluster?(conn.default_store)
        end
      end
    end
  end
end
