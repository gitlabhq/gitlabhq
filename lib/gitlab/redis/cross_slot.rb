# frozen_string_literal: true

module Gitlab
  module Redis
    module CrossSlot
      class Router
        attr_reader :node_mapping, :futures, :node_sequence, :cmd_queue

        delegate :respond_to_missing?, to: :@redis

        # This map contains redis-rb methods which does not map directly
        # to a standard Redis command. It is used transform unsupported commands to standard commands
        # to find the node key for unsupported commands.
        #
        # Redis::Cluster::Command only contains details of commands which the Redis Server
        # returns. Hence, commands like mapped_hmget and hscan_each internally will call the
        # base command, hmget and hscan respectively.
        #
        # See https://github.com/redis/redis-rb/blob/v4.8.0/lib/redis/cluster/command.rb
        UNSUPPORTED_CMD_MAPPING = {
          # Internally, redis-rb calls the supported Redis command and transforms the output.
          # See https://github.com/redis/redis-rb/blob/v4.8.0/lib/redis/commands/hashes.rb#L104
          mapped_hmget: :hmget
        }.freeze

        # Initializes the CrossSlot::Router
        # @param {::Redis}
        def initialize(redis)
          @redis = redis
          @node_mapping = {}
          @futures = {}
          @node_sequence = []
          @cmd_queue = []
        end

        # For now we intercept every redis.call and return a Gitlab-Future object.
        # This method groups every commands to a node for fan-out. Commands are grouped using the first key.
        #
        # rubocop:disable Style/MissingRespondToMissing
        def method_missing(cmd, *args, **kwargs, &blk)
          # Note that we can re-map the command without affecting execution as it is
          # solely for finding the node key. The original cmd will be executed.
          node = @redis._client._find_node_key([UNSUPPORTED_CMD_MAPPING.fetch(cmd, cmd)] + args)

          @node_mapping[node] ||= []
          @futures[node] ||= []

          @node_sequence << node
          @node_mapping[node] << [cmd, args, kwargs || {}, blk]
          f = Future.new
          @futures[node] << f
          @cmd_queue << [f, cmd, args, kwargs || {}, blk]
          f
        end
        # rubocop:enable Style/MissingRespondToMissing
      end

      # Wraps over redis-rb's Future in
      # https://github.com/redis/redis-rb/blob/v4.8.0/lib/redis/pipeline.rb#L244
      class Future
        def set(future, is_val = false)
          @redis_future = future
          @is_val = is_val
        end

        def value
          return @redis_val if @is_val

          @redis_future.value
        end
      end

      # Pipeline allows cross-slot pipelined to be called. The fan-out logic is implemented in
      # https://github.com/redis-rb/redis-cluster-client/blob/master/lib/redis_client/cluster/pipeline.rb
      # which is available in redis-rb v5.0.
      #
      # This file can be deprecated after redis-rb v4.8.0 is upgraded to v5.0
      class Pipeline
        # Initializes the CrossSlot::Pipeline
        # @param {::Redis}
        def initialize(redis)
          @redis = redis
        end

        # pipelined is used in place of ::Redis `.pipelined` when running in a cluster context
        # where cross-slot operations may happen.
        def pipelined(&block)
          # Directly call .pipelined and defer the pipeline execution to MultiStore.
          # MultiStore could wrap over 0, 1, or 2 Redis Cluster clients, handling it here
          # will not work for 2 clients since the key-slot topology can differ.
          if use_cross_slot_pipelining?
            router = Router.new(@redis)
            yield router
            execute_commands(router)
          else
            # use redis-rb's pipelined method
            @redis.pipelined(&block)
          end
        end

        private

        def use_cross_slot_pipelining?
          !@redis.instance_of?(::Gitlab::Redis::MultiStore) && @redis._client.instance_of?(::Redis::Cluster)
        end

        def execute_commands(router)
          router.node_mapping.each do |node_key, commands|
            # TODO possibly use Threads to speed up but for now `n` is 3-5 which is small.
            @redis.pipelined do |p|
              commands.each_with_index do |command, idx|
                future = router.futures[node_key][idx]
                cmd, args, kwargs, blk = command
                future.set(p.public_send(cmd, *args, **kwargs, &blk)) # rubocop:disable GitlabSecurity/PublicSend
              end
            end
          end

          router.node_sequence.map do |node_key|
            router.futures[node_key].shift.value
          end
        rescue ::Redis::CommandError => err
          if err.message.start_with?('MOVED', 'ASK')
            Gitlab::ErrorTracking.log_exception(err)
            return execute_commands_sequentially(router)
          end

          raise
        end

        def execute_commands_sequentially(router)
          router.cmd_queue.map do |command|
            future, cmd, args, kwargs, blk = command
            future.set(@redis.public_send(cmd, *args, **kwargs, &blk), true) # rubocop:disable GitlabSecurity/PublicSend
            future.value
          end
        end
      end
    end
  end
end
