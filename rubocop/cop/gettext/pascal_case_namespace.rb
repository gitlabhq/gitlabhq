# frozen_string_literal: true

module RuboCop
  module Cop
    module Gettext
      # Checks that namespaces used in s_() and n_() are PascalCase,
      # containing only alphanumeric characters [a-zA-Z0-9].
      #
      # A namespace is defined as a sequence of word characters and spaces
      # at the start of the string, ending with a non-space character
      # immediately before `|`. This avoids false positives on strings like
      # s_('Hello | World') which have a space before `|`.
      #
      # @example
      #
      #   # bad
      #   s_('my_namespace|Hello')
      #   s_('Add passkey|Add passkey')
      #   s_('Time Display|System')
      #   n_('my_namespace|Apple', 'my_namespace|Apples', count)
      #
      #   # good
      #   s_('MyNamespace|Hello')
      #   s_('Wiki404|Page not found')
      #   n_('MergeRequest|Apple', 'MergeRequest|Apples', count)
      #
      class PascalCaseNamespace < RuboCop::Cop::Base
        MSG = 'Namespace `%{namespace}` must be in PascalCase format, spaces and underscores are not valid.'

        RESTRICT_ON_SEND = %i[s_ n_].freeze

        # Matches a namespace: anchored at the start of the string, consists
        # of word characters and spaces, ending with a non-space before `|`.
        # This matches real namespaces including spaced ones (e.g. Add passkey,
        # Time Display) while avoiding false positives on strings like
        # s_('Hello | World') which have a space before `|`.
        NAMESPACE_REGEX = /\A([\w ]*\w)\|/

        VALID_NAMESPACE_REGEX = /\A[a-zA-Z0-9]*\z/

        def on_send(node)
          # For n_(), check first two arguments (singular and plural).
          # For s_(), check first argument only.
          args = node.method?(:n_) ? node.arguments.first(2) : node.arguments.first(1)

          args.each do |arg|
            namespace = extract_namespace(arg)
            next unless namespace
            next if VALID_NAMESPACE_REGEX.match?(namespace)

            add_offense(arg, message: format(MSG, namespace: namespace))
          end
        end
        alias_method :on_csend, :on_send

        private

        def extract_namespace(node)
          value = string_value(node)
          return unless value

          match = NAMESPACE_REGEX.match(value)
          match[1] if match
        end

        def string_value(node)
          if node.str_type?
            node.value
          elsif node.dstr_type?
            first_child = node.children.first
            first_child.value if first_child.str_type?
          end
        end
      end
    end
  end
end
