# frozen_string_literal: true

module Gitlab
  module Patch
    module RedisCacheStore
      # The initialize calls retrieve_pool_options method:
      # https://github.com/rails/rails/blob/v7.1.5.1/activesupport/lib/active_support/cache/redis_cache_store.rb#L149
      # In Rails 7.1 the method changed and now it always returns something
      #
      # - https://github.com/rails/rails/blob/v7.0.8.7/activesupport/lib/active_support/cache.rb#L183
      # - https://github.com/rails/rails/blob/v7.1.5.1/activesupport/lib/active_support/cache.rb#L206
      #
      # As a result, an unexpected connection pool is initialized.
      # This path always initializes redis without a connection pool, the pool is initialized in a wrapper.
      def initialize(*args, **kwargs)
        super

        @redis = self.class.build_redis(redis: kwargs[:redis])
      end

      # We will try keep patched code explicit and matching the original signature in
      # https://github.com/rails/rails/blob/v7.1.3.4/activesupport/lib/active_support/cache/redis_cache_store.rb#L324
      def read_multi_entries(names, **options)
        return super unless enable_rails_cache_pipeline_patch?
        return super unless use_patched_mget?

        ::Gitlab::Redis::ClusterUtil.batch_entries(names) do |batched_names|
          super(batched_names, **options)
        end.reduce({}, &:merge)
      end

      # `delete_multi_entries` in Rails runs a multi-key `del` command
      # patch will run pipelined single-key `del` for Redis Cluster compatibility
      def delete_multi_entries(entries, **options)
        return super unless enable_rails_cache_pipeline_patch?

        ::Gitlab::Redis::ClusterUtil.batch_entries(entries) do |batched_names|
          super(batched_names)
        end.sum
      end

      # `pipeline_entries` is used by Rails for multi-key writes
      # patch will run pipelined single-key for Redis Cluster compatibility
      def pipeline_entries(entries, &block)
        return super unless enable_rails_cache_pipeline_patch?

        redis.with do |conn|
          ::Gitlab::Redis::ClusterUtil.batch(entries, conn, &block)
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
