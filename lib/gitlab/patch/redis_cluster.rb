# frozen_string_literal: true

# Patch to expose `find_node_key` method for cross-slot pipelining
# In redis v5.0.x, cross-slot pipelining is implemented via redis-cluster-client.
# This patch should be removed since there is no need for it.
# Gitlab::Redis::CrossSlot and its usage should be removed as well.
if Gem::Version.new(Redis::VERSION) != Gem::Version.new('4.8.0')
  raise 'New version of redis detected, please remove or update this patch'
end

module Gitlab
  module Patch
    module RedisCluster
      # _find_node_key exposes a private function of the same name in Redis::Cluster.
      # See https://github.com/redis/redis-rb/blob/v4.8.0/lib/redis/cluster.rb#L282
      def _find_node_key(command)
        find_node_key(command)
      end
    end
  end
end
