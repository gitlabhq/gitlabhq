# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that disallows the use of `Gitlab::SQL::Except`, in favour of using
      # the `FromExcept` module.
      class Except < RuboCop::Cop::Cop
        MSG = 'Use the `FromExcept` concern, instead of using `Gitlab::SQL::Except` directly'

        def_node_matcher :raw_except?, <<~PATTERN
          (send (const (const (const nil? :Gitlab) :SQL) :Except) :new ...)
        PATTERN

        def on_send(node)
          return unless raw_except?(node)

          add_offense(node, location: :expression)
        end
      end
    end
  end
end
