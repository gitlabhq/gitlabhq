# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that disallows the use of `Gitlab::SQL::Union`, in favour of using
      # the `FromUnion` module.
      class Union < RuboCop::Cop::Base
        MSG = 'Use the `FromUnion` concern, instead of using `Gitlab::SQL::Union` directly'

        def_node_matcher :raw_union?, <<~PATTERN
          (send (const (const (const nil? :Gitlab) :SQL) :Union) :new ...)
        PATTERN

        def on_send(node)
          return unless raw_union?(node)

          add_offense(node)
        end
      end
    end
  end
end
