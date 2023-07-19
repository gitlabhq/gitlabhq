# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that denylists the use of `destroy_all`.
    class DestroyAll < RuboCop::Cop::Base
      MSG = 'Use `delete_all` instead of `destroy_all`. ' \
        '`destroy_all` will load the rows into memory, then execute a ' \
        '`DELETE` for every individual row.'

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
