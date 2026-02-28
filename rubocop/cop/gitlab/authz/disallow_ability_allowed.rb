# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Authz
        # Prevents the use of `Ability.allowed?` inside policy files.
        #
        # Policy files should express permissions declaratively using
        # `DeclarativePolicy` conditions and rules rather than delegating
        # back to `Ability.allowed?`, which can cause circular lookups
        # and makes authorization logic harder to reason about.
        #
        # @example
        #   # bad
        #   condition(:can_read_project) { Ability.allowed?(user, :read_project, project) }
        #   condition(:can_read_project) { user.can?(:read_project, project) }
        #
        #   # good
        #   condition(:can_read_project) { can?(:read_project, project) }
        #
        class DisallowAbilityAllowed < ::RuboCop::Cop::Base
          MSG_ABILITY = 'Do not use `Ability.allowed?` in policy files. ' \
            'Use `can?` or define a condition using DeclarativePolicy primitives instead.'
          MSG_USER_CAN = 'Do not call `.can?` on an object in policy files. ' \
            'Use the bare `can?` helper from DeclarativePolicy instead.'

          # Matches: Ability.allowed?(...)
          # @!method ability_allowed_call?(node)
          def_node_matcher :ability_allowed_call?, <<~PATTERN
            (call
              (const {nil? cbase} :Ability)
              :allowed?
              ...)
          PATTERN

          # Matches: <any_receiver>.can?(...)
          # @!method user_can_call?(node)
          def_node_matcher :user_can_call?, <<~PATTERN
            (call !nil? :can? ...)
          PATTERN

          def on_send(node)
            if ability_allowed_call?(node)
              add_offense(node, message: MSG_ABILITY)
            elsif user_can_call?(node)
              add_offense(node, message: MSG_USER_CAN)
            end
          end
          alias_method :on_csend, :on_send
        end
      end
    end
  end
end
