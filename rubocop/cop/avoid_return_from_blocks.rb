# frozen_string_literal: true

module RuboCop
  module Cop
    # Checks for return inside blocks.
    # Whitelisted methods are ignored: each, each_filename, times, loop, define_method.
    #
    # @example
    #   # bad
    #   call do
    #     do_something
    #     return if something_else
    #   end
    #
    #   # good
    #   call do
    #     do_something
    #     break if something_else
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
          next if container_block_whitelisted?(return_node)
          next if return_inside_method_definition?(return_node)

          add_offense(return_node)
        end
      end

      private

      def container_block_whitelisted?(current_node)
        while current_node = current_node.parent
          break if current_node.type == :block
        end

        WHITELISTED_METHODS.include?(current_node.method_name)
      end

      def return_inside_method_definition?(current_node)
        while current_node = current_node.parent
          # we found def before the block, that means the return is inside a method definition
          return true if current_node.type == :def
          return false if current_node.type == :block
        end
      end
    end
  end
end
