# frozen_string_literal: true

module Gitlab
  module Patch
    module RedisCacheStore
      # We will try keep patched code explicit and matching the original signature in
      # https://github.com/rails/rails/blob/v6.1.7.2/activesupport/lib/active_support/cache/redis_cache_store.rb#L361
      def read_multi_mget(*names) # rubocop:disable Style/ArgumentsForwarding
        return super unless enable_rails_cache_pipeline_patch?
        return super unless use_patched_mget?

        patched_read_multi_mget(*names) # rubocop:disable Style/ArgumentsForwarding
      end

      # `delete_multi_entries` in Rails runs a multi-key `del` command
      # patch will run pipelined single-key `del` for Redis Cluster compatibility
      def delete_multi_entries(entries, **options)
        return super unless enable_rails_cache_pipeline_patch?

        delete_count = 0
        redis.with do |conn|
          entries.each_slice(pipeline_batch_size) do |subset|
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
          redis.with do |c|
            pipeline_mget(c, keys)
          end
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
        keys.each_slice(pipeline_batch_size).flat_map do |subset|
          conn.pipelined do |p|
            subset.each { |key| p.get(key) }
          end
        end
      end

      private

      def pipeline_batch_size
        @pipeline_batch_size ||= [ENV['GITLAB_REDIS_CLUSTER_PIPELINE_BATCH_LIMIT'].to_i, 1000].max
      end

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
