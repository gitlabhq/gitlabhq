# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Authz
        # Detects permission categories that must not be checked at enforcement
        # points (Ability.allowed?, can?, authorize):
        #
        # - Coarse manage_* / admin_* permissions (use a granular permission).
        # - Role access permissions such as guest_access (don't gate on roles).
        # - Private (underscore-prefixed) permissions, which exist only to
        #   compose access inside policy rules and must not be enforced directly
        #   (check the public permission a caller should hold instead).
        #
        # Composition inside policy rules (e.g. `rule { can?(:_read_authored_issue) }`)
        # is unaffected because this cop is excluded from policy files.
        #
        # @example
        #   # bad
        #   Ability.allowed?(user, :manage_issue, project)
        #   Ability.allowed?(user, :admin_issue, project)
        #   can?(current_user, :_run_dast_pipeline, project)
        #
        #   # good
        #   Ability.allowed?(user, :update_issue, project)
        #   can?(current_user, :run_pipeline, project)
        class PermissionCheck < RuboCop::Cop::Base
          MSG_MANAGE = 'Avoid using coarse permission checks such as manage_* or admin_* permissions. ' \
            'Use granular permissions instead.'

          MSG_ROLE_ACCESS = 'Role access permissions are not allowed for access checks.'

          MSG_PRIVATE = 'Do not check private (underscore-prefixed) permissions at enforcement points. ' \
            'Private permissions are for composition inside policy rules only; check a public permission instead.'

          PERMISSION_PATTERN = /\A(manage_|admin_)/
          PRIVATE_PERMISSION_PATTERN = /\A_/
          ACCESS_PERMISSIONS = %w[
            guest_access
            planner_access
            reporter_access
            developer_access
            maintainer_access
            owner_access
          ].freeze

          # @!method ability_allowed_call?(node)
          def_node_matcher :ability_allowed_call?, <<~PATTERN
          (call (const nil? :Ability) :allowed? _ (sym $_) _)
          PATTERN

          # @!method user_can_call?(node)
          def_node_matcher :user_can_call?, <<~PATTERN
          (call _ :can? (sym $_) _?)
          PATTERN

          # @!method user_can_three_arg_call?(node)
          def_node_matcher :user_can_three_arg_call?, <<~PATTERN
          (call _ :can? _ (sym $_) _)
          PATTERN

          # @!method authorize_kwarg?(node)
          def_node_matcher :authorize_kwarg?, <<~PATTERN
          (pair (sym :authorize) (sym $_))
          PATTERN

          # @!method authorize_call?(node)
          def_node_matcher :authorize_call?, <<~PATTERN
          (call _ {:authorize :authorize!} $...)
          PATTERN

          def on_send(node)
            check_ability_allowed(node) ||
              check_user_can(node) ||
              check_user_can_three_arg(node) ||
              check_authorize_call(node)
          end
          alias_method :on_csend, :on_send

          def on_pair(node)
            permission_sym = authorize_kwarg?(node)
            return unless permission_sym

            msg = message_for(permission_sym)
            return unless msg

            add_offense(node.value, message: msg)
          end

          private

          def check_ability_allowed(node)
            permission_sym = ability_allowed_call?(node)
            return unless permission_sym

            check_permission(node, permission_sym)
          end

          def check_user_can(node)
            permission_sym = user_can_call?(node)
            return unless permission_sym

            check_permission(node, permission_sym)
          end

          def check_user_can_three_arg(node)
            permission_sym = user_can_three_arg_call?(node)
            return unless permission_sym

            check_permission(node, permission_sym)
          end

          def check_authorize_call(node)
            args = authorize_call?(node)
            return unless args

            offense_added = false
            args.each do |arg|
              next unless arg.sym_type?

              msg = message_for(arg.value)
              next unless msg

              add_offense(arg, message: msg)
              offense_added = true
            end

            offense_added
          end

          def check_permission(node, permission_sym)
            msg = message_for(permission_sym)
            return unless msg

            arg = node.arguments.find { |arg| arg.sym_type? && arg.value == permission_sym }
            add_offense(arg, message: msg)
          end

          def message_for(permission_sym)
            permission_name = permission_sym.to_s

            if PERMISSION_PATTERN.match?(permission_name)
              MSG_MANAGE
            elsif PRIVATE_PERMISSION_PATTERN.match?(permission_name)
              MSG_PRIVATE
            elsif ACCESS_PERMISSIONS.include?(permission_name)
              MSG_ROLE_ACCESS
            end
          end
        end
      end
    end
  end
end
