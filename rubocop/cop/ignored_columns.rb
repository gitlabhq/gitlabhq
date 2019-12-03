# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that blacklists the usage of Group.public_or_visible_to_user
    class IgnoredColumns < RuboCop::Cop::Cop
      MSG = 'Use `IgnoredColumns` concern instead of adding to `self.ignored_columns`.'

      def_node_matcher :ignored_columns?, <<~PATTERN
        (send (self) :ignored_columns)
      PATTERN

      def on_send(node)
        return unless ignored_columns?(node)

        add_offense(node, location: :expression)
      end
    end
  end
end
