# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that denylists the use of `destroy_all`.
    #
    # `destroy_all` loads all rows into memory and executes a DELETE
    # for each individual row, which is inefficient. Use `delete_all`
    # instead for better performance.
    #
    # @example
    #   # bad
    #   User.where(active: false).destroy_all
    #   @users.destroy_all
    #
    #   # good
    #   User.where(active: false).delete_all
    #   @users.delete_all
    #
    class DestroyAll < RuboCop::Cop::Base
      MSG = 'Use `delete_all` instead of `destroy_all`. ' \
        '`destroy_all` will load the rows into memory, then execute a ' \
        '`DELETE` for every individual row.'

      # @!method destroy_all?(node)
      def_node_matcher :destroy_all?, <<~PATTERN
        (send {send ivar lvar const} :destroy_all ...)
      PATTERN

      def on_send(node)
        return unless destroy_all?(node)

        add_offense(node)
      end
    end
  end
end
