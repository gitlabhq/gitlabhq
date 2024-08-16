# frozen_string_literal: true

module Gitlab
  module Instrumentation
    module RedisClusterRouter
      # Patch the `send_command` method in RedisClient::Cluster::Router
      # See https://github.com/redis-rb/redis-cluster-client/blob/v0.8.2/lib/redis_client/cluster/router.rb#L34
      #
      # When a Redis Cluster is in a fail state, we might not have metrics on the server-side.
      # This allows the application to dump its local topology state to get the client-side perspective of any
      # cluster failure.
      def send_command(method, command, *args, &block)
        super
      rescue ::RedisClient::Cluster::NodeMightBeDown => e
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- this class is used to monkeypatch RedisClient::Cluster::Router
        slots_map = Gitlab::Instrumentation::RedisClusterRouter.format_slotmap(@node.instance_variable_get(:@slots))
        Gitlab::ErrorTracking.log_exception(
          e,
          node_keys: @node.node_keys,
          slots_map: slots_map
        )

        inst = instrumentation_class(@config)
        inst.instance_count_exception(e) if inst
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        raise e
      end

      private

      def instrumentation_class(config)
        name = config.client_config.dig(:custom, :instrumentation_class)
        return unless name

        ::Gitlab::Instrumentation::Redis.storage_hash[name]
      end

      class << self
        def format_slotmap(slots)
          return {} unless slots

          slotmap = {}
          (0..16383).each do |c|
            node_key = slots[c]
            next unless node_key

            slotmap[node_key] ||= []
            slotmap[node_key] << c
          end

          slotmap.transform_values { |v| compact_array(v) }
        end

        # compact_array converts an array of integers into a range string
        # e.g. [0, 1, 2, 4, 5, 6] to "0-2,4-6"
        def compact_array(arr)
          return "" if arr.empty?

          range = ""
          prev = nil
          arr.each do |i|
            if prev.nil?
              range += i.to_s
            elsif prev + 1 < i
              range += "-#{prev},#{i}"
            end

            prev = i
          end
          range += "-#{prev}"

          range
        end
      end
    end
  end
end
