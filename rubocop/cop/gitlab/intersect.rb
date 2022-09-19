# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that disallows the use of `Gitlab::SQL::Intersect`, in favour of using
      # the `FromIntersect` module.
      class Intersect < RuboCop::Cop::Base
        MSG = 'Use the `FromIntersect` concern, instead of using `Gitlab::SQL::Intersect` directly'

        def_node_matcher :raw_intersect?, <<~PATTERN
          (send (const (const (const nil? :Gitlab) :SQL) :Intersect) :new ...)
        PATTERN

        def on_send(node)
          return unless raw_intersect?(node)

          add_offense(node)
        end
      end
    end
  end
end
