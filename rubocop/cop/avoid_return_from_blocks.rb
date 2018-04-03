# frozen_string_literal: true

module RuboCop
  module Cop
    # Checks for return inside blocks.
    # Whitelisted methods are ignored: each, each_filename, times, loop, define_method.
    #
    # @example
    #   # bad
    #   call do
    #     return if something
    #
    #     do_something_else
    #   end
    #
    #   # good
    #   call do
    #     break if something
    #
    #     do_something_else
    #   end
    #
    class AvoidReturnFromBlocks < RuboCop::Cop::Cop
      MSG = 'Do not return from a block, use next or break instead.'
      WHITELISTED_METHODS = %i[each each_filename times loop define_method lambda].freeze

      def on_block(node)
        block_body = node.body

        return unless block_body
        return if WHITELISTED_METHODS.include?(node.method_name)

        block_body.each_node(:return) do |return_node|
          next if container_block_for(return_node) != node
          next if container_block_whitelisted?(return_node)
          next if return_inside_method_definition?(return_node)

          add_offense(return_node)
        end
      end

      private

      def container_block_for(current_node)
        current_node = current_node.parent until current_node.type == :block

        current_node
      end

      def container_block_whitelisted?(current_node)
        WHITELISTED_METHODS.include?(container_block_for(current_node).method_name)
      end

      def return_inside_method_definition?(current_node)
        current_node = current_node.parent until %i[def block].include?(current_node.type)

        # if we found :def before :block in the nodes hierarchy
        current_node.type == :def
      end
    end
  end
end
