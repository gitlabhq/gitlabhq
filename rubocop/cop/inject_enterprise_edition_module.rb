# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that blacklists the injecting of extension specific modules before any lines which are not already injecting another module.
    # It allows multiple module injections as long as they're all at the end.
    class InjectEnterpriseEditionModule < RuboCop::Cop::Cop
      INVALID_LINE = 'Injecting extension modules must be done on the last line of this file' \
          ', outside of any class or module definitions'

      DISALLOWED_METHOD =
        'EE modules must be injected using `include_mod_with`, `extend_mod_with`, or `prepend_mod_with`'

      INVALID_ARGUMENT = 'extension modules to inject must be specified as a String'

      CHECK_LINE_METHODS =
        Set.new(%i[include_mod_with extend_mod_with prepend_mod_with]).freeze

      DISALLOW_METHODS = Set.new(%i[include extend prepend]).freeze

      COMMENT_OR_EMPTY_LINE = /^\s*(#.*|$)/.freeze

      CHECK_LINE_METHODS_REGEXP = Regexp.union((CHECK_LINE_METHODS + DISALLOW_METHODS).map(&:to_s) + [COMMENT_OR_EMPTY_LINE]).freeze

      def ee_const?(node)
        line = node.location.expression.source_line

        # We use `match?` here instead of RuboCop's AST matching, as this makes
        # it far easier to handle nested constants such as `EE::Foo::Bar::Baz`.
        line.match?(/(\s|\()('|")?(::)?(QA::)?EE::/)
      end

      def on_send(node)
        return unless check_method?(node)

        if DISALLOW_METHODS.include?(node.children[1])
          add_offense(node, message: DISALLOWED_METHOD)
        else
          verify_line_number(node)
          verify_argument_type(node)
        end
      end

      def verify_line_number(node)
        line = node.location.line
        buffer = node.location.expression.source_buffer
        last_line = buffer.last_line
        lines = buffer.source.split("\n")
        # We allow multiple includes, extends and prepends as long as they're all at the end.
        allowed_line = (line...last_line).all? { |i| CHECK_LINE_METHODS_REGEXP.match?(lines[i - 1]) }

        if allowed_line
          ignore_node(node)
        elsif line < last_line
          add_offense(node, message: INVALID_LINE)
        end
      end

      def verify_argument_type(node)
        argument = node.children[2]

        return if argument.str_type?

        add_offense(argument, message: INVALID_ARGUMENT)
      end

      def check_method?(node)
        name = node.children[1]

        if DISALLOW_METHODS.include?(name)
          ee_const?(node.children[2])
        else
          CHECK_LINE_METHODS.include?(name)
        end
      end

      # Automatically correcting these offenses is not always possible, as
      # sometimes code needs to be refactored to make this work. As such, we
      # only allow developers to easily blacklist existing offenses.
      def autocorrect(node)
        lambda do |corrector|
          corrector.insert_after(
            node.source_range,
            " # rubocop: disable #{cop_name}"
          )
        end
      end
    end
  end
end
