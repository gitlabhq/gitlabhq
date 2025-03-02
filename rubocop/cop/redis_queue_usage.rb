# frozen_string_literal: true

module RuboCop
  module Cop
    # This class complements Rubocop::Cop::SidekiqRedisCall by disallowing the use of
    # Gitlab::Redis::Queues with the exception of initialising Sidekiq and monitoring.
    class RedisQueueUsage < RuboCop::Cop::Base
      MSG = 'Gitlab::Redis::Queues should only be used by Sidekiq initializers. '\
        'Assignments or using its params to initialise another connection is not allowed.'

      def_node_matcher :calling_redis_queue_module_methods?, <<~PATTERN
        (send (const (const (const nil? :Gitlab) :Redis) :Queues) ...)
      PATTERN

      def_node_matcher :using_redis_queue_module_as_parameter?, <<~PATTERN
        (send ... (const (const (const nil? :Gitlab) :Redis) :Queues))
      PATTERN

      def_node_matcher :redis_queue_assignment?, <<~PATTERN
        ({lvasgn | ivasgn | cvasgn | gvasgn | casgn | masgn | op_asgn | or_asgn | and_asgn } ...
          `(const (const (const nil? :Gitlab) :Redis) :Queues))
      PATTERN

      def on_send(node)
        return unless using_redis_queue_module_as_parameter?(node) || calling_redis_queue_module_methods?(node)

        add_offense(node, message: MSG)
      end

      # offenses caught in assignment may overlap with on_send
      %i[on_lvasgn on_ivasgn on_cvasgn on_gvasgn on_casgn on_masgn on_op_asgn on_or_asgn on_and_asgn].each do |name|
        define_method(name) do |node|
          add_offense(node, message: MSG) if redis_queue_assignment?(node)
        end
      end
    end
  end
end
