# frozen_string_literal: true

module Gitlab
  module Patch
    module OldRedisCacheStore
      # We will try keep patched code explicit and matching the original signature in
      # https://github.com/rails/rails/blob/v6.1.7.2/activesupport/lib/active_support/cache/redis_cache_store.rb#L361
      def read_multi_mget(*names)
        return super unless enable_rails_cache_pipeline_patch?
        return super unless use_patched_mget?

        ::Gitlab::Redis::ClusterUtil.batch_entries(names) do |batched_names|
          super(*batched_names)
        end.reduce(&:merge)
      end

      # `delete_multi_entries` in Rails runs a multi-key `del` command
      # patch will run pipelined single-key `del` for Redis Cluster compatibility
      def delete_multi_entries(entries, **options)
        return super unless enable_rails_cache_pipeline_patch?

        ::Gitlab::Redis::ClusterUtil.batch_entries(entries) do |batched_names|
          super(batched_names)
        end.sum
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
