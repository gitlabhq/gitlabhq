# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Prevents direct calls to Users::Internal methods without organization context.
      #
      # @example
      #
      #   # bad
      #   Users::Internal.alert_bot
      #   Internal.support_bot
      #
      #   # good
      #   Users::Internal.in_organization(organization).alert_bot
      #   Users::Internal.in_organization(organization).support_bot
      #
      class UsersInternalOrganization < RuboCop::Cop::Base
        MSG = 'Use `Users::Internal.in_organization(organization)` before calling methods on `Users::Internal`.'

        # Methods that don't require organization context
        ALLOWED_METHODS = %i[
          in_organization
          try
          clear_memoization
          bot_avatar
          prepend
          prepend_mod
          include
          extend
        ].freeze

        # Match both ::Users::Internal.method and Internal.method patterns
        # @!method users_internal_call?(node)
        def_node_matcher :users_internal_call?, <<~PATTERN
          {
            (send
              (const
                (const {nil? cbase} :Users) :Internal)
              $_method_name
              ...)
            (send
              (const {nil? cbase} :Internal)
              $_method_name
              ...)
          }
        PATTERN

        def on_send(node)
          users_internal_call?(node) do |method_name|
            next if ALLOWED_METHODS.include?(method_name)
            next if chained_after_in_organization?(node)

            add_offense(node)
          end
        end
        alias_method :on_csend, :on_send

        private

        def chained_after_in_organization?(node)
          return false unless node.receiver

          receiver = node.receiver
          return true if receiver.send_type? && receiver.method?(:in_organization)

          false
        end
      end
    end
  end
end
