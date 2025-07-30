# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that prevents manually setting a queue in Sidekiq workers.
    class SidekiqOptionsQueue < RuboCop::Cop::Base
      MSG = 'Do not manually set a queue; `ApplicationWorker` sets one automatically.'

      # @!method sidekiq_options?(node)
      def_node_matcher :sidekiq_options?, <<~PATTERN
        (send nil? :sidekiq_options $...)
      PATTERN

      def on_send(node)
        return unless sidekiq_options?(node)

        node.first_argument.each_node(:pair) do |pair|
          key_name = pair.key.children[0]

          add_offense(pair) if key_name == :queue
        end
      end
    end
  end
end
