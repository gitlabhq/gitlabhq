# frozen_string_literal: true

module RuboCop
  module Cop
    # Checks for return inside blocks.
    # For more information see: https://gitlab.com/gitlab-org/gitlab-ce/issues/42889
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
      WHITELISTED_METHODS = %i[each each_filename times loop define_method lambda helpers class_methods describe included namespace validations].freeze

      def on_block(node)
        block_body = node.body

        return unless block_body
        return unless top_block?(node)

        block_body.each_node(:return) do |return_node|
          next if contained_blocks(node, return_node).all?(&method(:whitelisted?))

          add_offense(return_node)
        end
      end

      def top_block?(node)
        current_node = node
        top_block = nil

        while current_node && current_node.type != :def
          top_block = current_node if current_node.type == :block
          current_node = current_node.parent
        end

        top_block == node
      end

      def contained_blocks(node, current_node)
        blocks = []

        until node == current_node
          blocks << current_node if current_node.type == :block
          current_node = current_node.parent
        end

        blocks << node
      end

      def whitelisted?(block_node)
        WHITELISTED_METHODS.include?(block_node.method_name)
      end
    end
  end
end
