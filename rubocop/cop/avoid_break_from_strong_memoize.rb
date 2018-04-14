# frozen_string_literal: true

module RuboCop
  module Cop
    # Checks for break inside strong_memoize blocks.
    # For more information see: https://gitlab.com/gitlab-org/gitlab-ce/issues/42889
    #
    # @example
    #   # bad
    #   strong_memoize(:result) do
    #     break if something
    #
    #     do_an_heavy_calculation
    #   end
    #
    #   # good
    #   strong_memoize(:result) do
    #     next if something
    #
    #     do_an_heavy_calculation
    #   end
    #
    class AvoidBreakFromStrongMemoize < RuboCop::Cop::Cop
      MSG = 'Do not use break inside strong_memoize, use next instead.'

      def on_block(node)
        block_body = node.body

        return unless block_body
        return unless node.method_name == :strong_memoize

        block_body.each_node(:break) do |break_node|
          next if container_block_for(break_node) != node

          add_offense(break_node)
        end
      end

      private

      def container_block_for(current_node)
        current_node = current_node.parent until current_node.type == :block && current_node.method_name == :strong_memoize

        current_node
      end
    end
  end
end
