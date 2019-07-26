# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that blacklists the injecting of EE specific modules anywhere but on
    # the last line of a file. Injecting a module in the middle of a file will
    # cause merge conflicts, while placing it on the last line will not.
    class InjectEnterpriseEditionModule < RuboCop::Cop::Cop
      INVALID_LINE = 'Injecting EE modules must be done on the last line of this file' \
          ', outside of any class or module definitions'

      DISALLOWED_METHOD =
        'EE modules must be injected using `include_if_ee`, `extend_if_ee`, or `prepend_if_ee`'

      INVALID_ARGUMENT = 'EE modules to inject must be specified as a String'

      CHECK_LINE_METHODS =
        Set.new(%i[include_if_ee extend_if_ee prepend_if_ee]).freeze

      DISALLOW_METHODS = Set.new(%i[include extend prepend]).freeze

      def ee_const?(node)
        line = node.location.expression.source_line

        # We use `match?` here instead of RuboCop's AST matching, as this makes
        # it far easier to handle nested constants such as `EE::Foo::Bar::Baz`.
        line.match?(/(\s|\()('|")?(::)?EE::/)
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

        # Parser treats the final newline (if present) as a separate line,
        # meaning that a simple `line < last_line` would yield true even though
        # the expression is the last line _of code_.
        last_line -= 1 if buffer.source.end_with?("\n")

        add_offense(node, message: INVALID_LINE) if line < last_line
      end

      def verify_argument_type(node)
        argument = node.children[2]

        return if argument.str_type?

        add_offense(argument, message: INVALID_ARGUMENT)
      end

      def check_method?(node)
        name = node.children[1]

        if CHECK_LINE_METHODS.include?(name) || DISALLOW_METHODS.include?(name)
          ee_const?(node.children[2])
        else
          false
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
