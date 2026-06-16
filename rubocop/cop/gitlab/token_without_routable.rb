# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Checks for the use of add_authentication_token_field without
      # also defining a routable_token. Encoding routing information in
      # the token allows the HTTP Router to route requests to the correct
      # cell without an extra lookup.
      #
      # @example
      #   # bad
      #   add_authentication_token_field :foo
      #
      #   # good
      #   add_authentication_token_field :foo, routable_token: { payload: { c: ->(record) { record.cell_id } } }
      #
      class TokenWithoutRoutable < Base
        MSG = 'Tokens should be routable. ' \
          'See doc/development/cells/http_router.md#routing-based-on-routable-tokens for more information.'

        # @!method add_authentication_token_field?(node)
        def_node_matcher :add_authentication_token_field?, <<~PATTERN
          (send nil? :add_authentication_token_field ...)
        PATTERN

        # @!method routable_token?(node)
        def_node_matcher :routable_token?, <<~PATTERN
          (send nil? :add_authentication_token_field _ (hash <(pair (sym :routable_token) (hash ...)) ...>))
        PATTERN

        def on_send(node)
          return unless add_authentication_token_field?(node) && !routable_token?(node)

          add_offense(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
