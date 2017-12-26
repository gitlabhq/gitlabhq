require_relative '../spec_helpers'

module RuboCop
  module Cop
    # Cop that prevents manually setting a queue in Sidekiq workers.
    class SidekiqOptionsQueue < RuboCop::Cop::Cop
      include SpecHelpers

      MSG = 'Do not manually set a queue; `ApplicationWorker` sets one automatically.'.freeze

      def_node_matcher :sidekiq_options?, <<~PATTERN
        (send nil? :sidekiq_options $...)
      PATTERN

      def on_send(node)
        return if in_spec?(node)
        return unless sidekiq_options?(node)

        node.arguments.first.each_node(:pair) do |pair|
          key_name = pair.key.children[0]

          add_offense(pair, location: :expression) if key_name == :queue
        end
      end
    end
  end
end
