# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that prevents manually setting a queue in Sidekiq workers.
    class SidekiqRedisCall < RuboCop::Cop::Base
      MSG = 'Refrain from directly using Sidekiq.redis unless for migration. For admin operations, use Sidekiq APIs.'

      def_node_matcher :using_sidekiq_redis?, <<~PATTERN
        (send (const nil? :Sidekiq) :redis)
      PATTERN

      def on_send(node)
        add_offense(node, message: MSG) if using_sidekiq_redis?(node)
      end
    end
  end
end
