module RuboCop
  module Cop
    module Security
      class ToJson < RuboCop::Cop::Cop
        def_node_matcher :to_json?, <<~PATTERN
          (send !{nil hash} :to_json $...)
        PATTERN

        def_node_matcher :with_include?, <<~PATTERN
          (pair (sym :include) (hash $...))
        PATTERN

        def_node_matcher :with_only?, <<~PATTERN
          (pair
            (sym _)
            (hash
              (pair
                (sym :only) (array ...)
              )
            )
          )
        PATTERN

        MSG = "Don't use `to_json` without specifying `only`".freeze

        def on_send(node)
          matched = to_json?(node)
          return unless matched

          if matched[0].nil?
            # Empty `to_json` call
            add_offense(node, :expression)
          else
            # `to_json` with Hash arguments
            pairs = matched[0].pairs

            check_pairs(pairs)
          end
        end

        private

        def check_pairs(pairs)
          # Find `include: {...}` pairs
          with_include = pairs.collect { |pair| with_include?(pair) }.flatten.compact
          return if with_include.empty?

          with_include.each do |(child_node)|
            next if with_only?(child_node)

            add_offense(child_node, :expression)
          end
        end
      end
    end
  end
end
