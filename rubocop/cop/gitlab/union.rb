# frozen_string_literal: true
require_relative '../../spec_helpers'

module RuboCop
  module Cop
    module Gitlab
      # Cop that disallows the use of `Gitlab::SQL::Union`, in favour of using
      # the `FromUnion` module.
      class Union < RuboCop::Cop::Cop
        include SpecHelpers

        MSG = 'Use the `FromUnion` concern, instead of using `Gitlab::SQL::Union` directly'

        def_node_matcher :raw_union?, <<~PATTERN
          (send (const (const (const nil? :Gitlab) :SQL) :Union) :new ...)
        PATTERN

        def on_send(node)
          return unless raw_union?(node)
          return if in_spec?(node)

          add_offense(node, location: :expression)
        end
      end
    end
  end
end
