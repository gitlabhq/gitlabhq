# frozen_string_literal: true

module RuboCop
  module Cop
    module Gettext
      # Checks for `_(...)` calls where the string contains a namespace in the
      # format `Namespace|string`. A namespace is defined as a sequence of
      # word characters and spaces at the start of the string, ending with a
      # non-space character immediately before `|`.
      # When a namespace is present, `s_` should be used instead of `_`.
      #
      # @example
      #
      #   # bad
      #   _('Namespace|Hello')
      #   _('Namespace|Hello %{name}')
      #   _('AddPasskey|Add passkey')
      #
      #   # good
      #   s_('Namespace|Hello')
      #   s_('Namespace|Hello %{name}')
      #   s_('AddPasskey|Add passkey')
      #   _('Hello')
      #   _('Hello %{name}')
      #   _('Hello | World')
      #   _('Example: (feature|hotfix)/.*')
      #
      class ExtraneousNamespace < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Use `s_()` instead of `_()` when a namespace is present in the string.'

        RESTRICT_ON_SEND = %i[_].freeze

        # Matches a namespace: anchored at the start of the string, consists
        # of word characters and spaces, ending with a non-space before `|`.
        # This matches real namespaces including spaced ones (e.g. Add passkey,
        # Time Display) while avoiding false positives on regex-like strings
        # such as _('Example: (feature|hotfix)/.*') which start with `(`.
        NAMESPACE_REGEX = /^[\w ]*\w\|/

        def on_send(node)
          first_arg = node.first_argument
          value = string_value(first_arg)
          return unless value
          return unless NAMESPACE_REGEX.match?(value)

          add_offense(node.loc.selector) do |corrector|
            corrector.replace(node.loc.selector, 's_')
          end
        end
        alias_method :on_csend, :on_send

        private

        def string_value(node)
          return unless node

          if node.str_type?
            node.value
          elsif node.dstr_type?
            # Interpolated strings are handled by RuboCop::Cop::Gettext::StaticIdentifier.
            # This handles strings split across lines: 'hello' \
            #                                          'world'
            first_child = node.children.first
            first_child.value if first_child.str_type?
          end
        end
      end
    end
  end
end
