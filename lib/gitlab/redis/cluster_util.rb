# frozen_string_literal: true

module Gitlab
  module Redis
    module ClusterUtil
      class << self
        # clusters? is used to select Redis command types, on `true`, the subsequent
        # commands should be compatible with Redis Cluster.
        #
        # When working with MultiStore, if even 1 of 2 stores is a Redis::Cluster,
        # we should err on the side of caution and return `true `,
        def cluster?(obj)
          if obj.is_a?(MultiStore)
            cluster?(obj.primary_store) || cluster?(obj.secondary_store)
          else
            obj.is_a?(::Redis::Cluster)
          end
        end

        def batch_unlink(keys, redis)
          batch(keys, redis) do |pipeline, subset|
            subset.each { |key| pipeline.unlink(key) }
          end.sum
        end

        def batch_del(keys, redis)
          batch(keys, redis) do |pipeline, subset|
            subset.each { |key| pipeline.del(key) }
          end.sum
        end

        # Redis cluster alternative to mget
        def batch_get(keys, redis)
          batch(keys, redis) do |pipeline, subset|
            subset.map { |key| pipeline.get(key) }
          end.flatten
        end

        def batch_entries(entries)
          entries.each_slice(pipeline_batch_size).flat_map do |subset|
            yield subset
          end
        end

        def batch(entries, redis)
          entries.each_slice(pipeline_batch_size).flat_map do |subset|
            redis.pipelined do |pipeline|
              yield pipeline, subset
            end
          end
        end

        private

        def pipeline_batch_size
          @pipeline_batch_size ||= [ENV['GITLAB_REDIS_CLUSTER_PIPELINE_BATCH_LIMIT'].to_i, 1000].max
        end
      end
    end
  end
end
