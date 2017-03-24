module RuboCop
  module Cop
    module Security
      class ToJson < RuboCop::Cop::Cop
        MSG = "Don't use `to_json` without specifying `only`".freeze

        def_node_matcher :to_json?, <<~PATTERN
          (send !{nil hash} :to_json $...)
        PATTERN

        # Check if node is a `only: ...` pair
        def_node_matcher :only_pair?, <<~PATTERN
          (pair (sym :only) ...)
        PATTERN

        # Check if node is a `include: {...}` pair
        def_node_matcher :include_pair?, <<~PATTERN
          (pair (sym :include) (hash $...))
        PATTERN

        # Check for a `only: [...]` pair anywhere in the node
        def_node_search :contains_only?, <<~PATTERN
          (pair (sym :only) (array ...))
        PATTERN

        def on_send(node)
          matched = to_json?(node)
          return unless matched

          @_has_top_level_only = false

          if matched[0].nil?
            # Empty `to_json` call
            add_offense(node, :expression)
          else
            options = matched.first

            # If `to_json` was given an argument that isn't a Hash, we don't
            # know what to do here, so just move along
            return unless options.hash_type?

            options.each_child_node do |child_node|
              check_pair(child_node)
            end

            # Add a top-level offense for the entire argument list, but only if
            # we haven't yet added any offenses to the child Hash values (such
            # as `include`)
            add_offense(node.children.last, :expression) if requires_only?
          end
        end

        private

        def requires_only?
          return false if @_has_top_level_only

          offenses.count.zero?
        end

        def check_pair(pair)
          if only_pair?(pair)
            @_has_top_level_only = true
          elsif include_pair?(pair)
            includes = pair.value

            includes.each_child_node do |child_node|
              next if contains_only?(child_node)

              add_offense(child_node, :expression)
            end
          end
        end
      end
    end
  end
end
