# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Authz
        # Prevents the use of `user.highest_role` or `@user.highest_role` in policy files.
        #
        # `highest_role` returns the highest role a user has anywhere on the instance
        # and is unsafe to use in declarative policy since it is not scoped to the
        # subject being authorized. It should be reserved for billing purposes only.
        #
        # @example
        #   # bad
        #   condition(:is_developer) { @user.highest_role >= Gitlab::Access::DEVELOPER }
        #
        #   # good
        #   condition(:is_developer) { team_access_level >= Gitlab::Access::DEVELOPER }
        #
        class AvoidHighestRoleUsage < ::RuboCop::Cop::Base
          MSG = 'Do not use `highest_role` in policy files. ' \
            'It returns the highest role a user has anywhere on the instance and is unsafe ' \
            'for authorization. Use subject-scoped access level checks instead, such as ' \
            '`team_access_level` or `project.team.developer?(user)`.'

          # Matches: user.highest_role or @user.highest_role
          # @!method highest_role_call?(node)
          def_node_matcher :highest_role_call?, <<~PATTERN
            (call _ :highest_role ...)
          PATTERN

          def on_send(node)
            return unless highest_role_call?(node)

            add_offense(node)
          end
          alias_method :on_csend, :on_send
        end
      end
    end
  end
end
