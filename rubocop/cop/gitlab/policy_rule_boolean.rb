# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # This cop checks for usage of boolean operators in rule blocks, which
      # does not work because conditions are objects, not booleans.
      #
      # @example
      #
      # # bad, `conducts_electricity` returns a Rule object, not a boolean!
      # rule { conducts_electricity && batteries }.enable :light_bulb
      #
      # # good
      # rule { conducts_electricity & batteries }.enable :light_bulb
      #
      # @example
      #
      # # bad, `conducts_electricity` returns a Rule object, so the ternary is always going to be true
      # rule { conducts_electricity ? can?(:magnetize) : batteries }.enable :motor
      #
      # # good
      # rule { conducts_electricity & can?(:magnetize) }.enable :motor
      # rule { ~conducts_electricity & batteries }.enable :motor
      class PolicyRuleBoolean < RuboCop::Cop::Base
        def_node_search :has_and_operator?, <<~PATTERN
          (and ...)
        PATTERN

        def_node_search :has_or_operator?, <<~PATTERN
          (or ...)
        PATTERN

        def_node_search :has_if?, <<~PATTERN
          (if ...)
        PATTERN

        def on_block(node)
          return unless node.method_name == :rule

          if has_and_operator?(node)
            add_offense(node, message: '&& is not allowed within a rule block. Did you mean to use `&`?')
          end

          if has_or_operator?(node)
            add_offense(node, message: '|| is not allowed within a rule block. Did you mean to use `|`?')
          end

          if has_if?(node)
            add_offense(node, message: 'if and ternary operators are not allowed within a rule block.')
          end
        end
      end
    end
  end
end
