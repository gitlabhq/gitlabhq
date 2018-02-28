# frozen_string_literal: true

module RuboCop
  module Cop
    # Ensures a line break after guard clauses.
    #
    # @example
    #   # bad
    #   return unless condition
    #   do_stuff
    #
    #   # good
    #   return unless condition
    #
    #   do_stuff
    #
    #   # bad
    #   raise if condition
    #   do_stuff
    #
    #   # good
    #   raise if condition
    #
    #   do_stuff
    #
    #   Multiple guard clauses are allowed without
    #   line break.
    #
    #   # good
    #   return unless condition_a
    #   return unless condition_b
    #
    #   do_stuff
    #
    #   Guard clauses in case statement are allowed without
    #   line break.
    #
    #   # good
    #   case model
    #     when condition_a
    #       return true unless condition_b
    #     when
    #       ...
    #   end
    #
    #   Guard clauses before end are allowed without
    #   line break.
    #
    #   # good
    #   if condition_a
    #     do_something
    #   else
    #     do_something_else
    #     return unless condition
    #   end
    #
    #   do_something_more
    class LineBreakAfterGuardClauses < RuboCop::Cop::Cop
      MSG = 'Add a line break after guard clauses'

      def_node_matcher :guard_clause_node?, <<-PATTERN
        [{(send nil? {:raise :fail :throw} ...) return break next} single_line?]
      PATTERN

      def on_if(node)
        return unless node.single_line?
        return unless guard_clause?(node)
        return if next_line(node).blank? || clause_last_line?(next_line(node)) || guard_clause?(next_sibling(node))

        add_offense(node, :expression, MSG)
      end

      def autocorrect(node)
        lambda do |corrector|
          corrector.insert_after(node.loc.expression, "\n")
        end
      end

      private

      def guard_clause?(node)
        return false unless node.if_type?

        guard_clause_node?(node.if_branch)
      end

      def next_sibling(node)
        node.parent.children[node.sibling_index + 1]
      end

      def next_line(node)
        processed_source[node.loc.line]
      end

      def clause_last_line?(line)
        line =~ /^\s*(?:end|elsif|else|when|rescue|ensure)/
      end
    end
  end
end
