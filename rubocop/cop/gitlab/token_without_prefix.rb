# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Checks for the use of add_authentication_token_field without
      # also defining a prefix. Using a prefix for each token type
      # allows easier secret detection if it leaks.
      #
      # @example
      #   # bad
      #   add_authentication_token_field :foo
      #
      #   # good
      #   add_authentication_token_field :foo, format_with_prefix: method_name_here
      #
      class TokenWithoutPrefix < Base
        MSG = 'Tokens should be prefixed. ' \
              'See doc/development/secure_coding_guidelines.md#token-prefixes for more information.'

        def_node_matcher :add_authentication_token_field?, <<~PATTERN
          (send nil? :add_authentication_token_field ...)
        PATTERN
        def_node_matcher :format_with_prefix?, <<~PATTERN
          (send nil? :add_authentication_token_field (sym $_)* (hash <$(pair (sym :format_with_prefix) _) ...>))
        PATTERN

        def on_send(node)
          return unless add_authentication_token_field?(node) && !format_with_prefix?(node)

          add_offense(node)
        end
      end
    end
  end
end
