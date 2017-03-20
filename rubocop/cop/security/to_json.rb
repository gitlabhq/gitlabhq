module RuboCop
  module Cop
    module Security
      class ToJson < RuboCop::Cop::Cop
        def_node_matcher :to_json?, <<~PATTERN
          (send !{nil hash} :to_json $...)
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

        def_node_matcher :with_include?, <<~PATTERN
          (pair (sym :include) (hash $...))
        PATTERN

        def_node_search :with_only?, <<~PATTERN
          (pair (sym :only) (array ...))
        PATTERN

        def check_pairs(pairs)
          nodes = pairs.collect { |pair| with_include?(pair) }.flatten.compact

          # Check the pairs themselves if we didn't find any `include:` above
          nodes = pairs if nodes.empty?

          nodes.each do |child_node|
            next if with_only?(child_node)

            add_offense(child_node, :expression)
          end
        end
      end
    end
  end
end
