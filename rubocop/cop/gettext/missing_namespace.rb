# frozen_string_literal: true

module RuboCop
  module Cop
    module Gettext
      # Checks for `s_(...)` calls where the string does not contain a namespace
      # in the format `Namespace|string`. A namespace is defined as a sequence
      # of word characters and spaces at the start of the string, ending with a
      # non-space character immediately before `|`.
      # When no namespace is present, `s_` is equivalent to `_` and should be
      # replaced with it.
      #
      # @example
      #
      #   # bad
      #   s_('Hello')
      #   s_('Hello %{name}')
      #   s_('Hello | World')
      #
      #   # good
      #   _('Hello')
      #   _('Hello %{name}')
      #   _('Hello | World')
      #   s_('Namespace|Hello')
      #   s_('Namespace|Hello %{name}')
      #   s_('AddPasskey|Add passkey')
      #   s_('Time Display|System')
      #
      class MissingNamespace < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Use `_()` instead of `s_()` when no namespace is present in the string.'

        RESTRICT_ON_SEND = %i[s_].freeze

        # Matches a namespace: anchored at the start of the string, consists
        # of word characters and spaces, ending with a non-space before `|`.
        # This matches real namespaces including spaced ones (e.g. Add passkey,
        # Time Display) while avoiding false positives on strings like
        # s_('Hello | World') which have a space before `|`.
        NAMESPACE_REGEX = /^[\w ]*\w\|/

        def on_send(node)
          first_arg = node.first_argument
          value = string_value(first_arg)
          return unless value
          return if NAMESPACE_REGEX.match?(value)

          add_offense(node.loc.selector) do |corrector|
            corrector.replace(node.loc.selector, '_')
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
