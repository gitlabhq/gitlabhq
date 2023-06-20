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
            obj.respond_to?(:_client) && obj._client.is_a?(::Redis::Cluster)
          end
        end

        def batch_unlink(keys, redis)
          expired_count = 0
          keys.each_slice(1000) do |subset|
            expired_count += Gitlab::Redis::CrossSlot::Pipeline.new(redis).pipelined do |pipeline|
              subset.each { |key| pipeline.unlink(key) }
            end.sum
          end
          expired_count
        end
      end
    end
  end
end
