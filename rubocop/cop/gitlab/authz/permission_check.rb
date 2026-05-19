# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Authz
        # Detects permission checks for manage_* and admin_* permissions
        # using Ability.allowed? or can? methods.
        #
        # @example
        #   # bad
        #   Ability.allowed?(user, :manage_issue, project)
        #   Ability.allowed?(user, :admin_issue, project)
        #
        #   # good
        #   Ability.allowed?(user, :update_issue, project)
        class PermissionCheck < RuboCop::Cop::Base
          MSG_MANAGE = 'Avoid using coarse permission checks such as manage_* or admin_* permissions. ' \
            'Use granular permissions instead.'

          MSG_ROLE_ACCESS = 'Role access permissions are not allowed for access checks.'

          PERMISSION_PATTERN = /\A(manage_|admin_)/
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
            elsif ACCESS_PERMISSIONS.include?(permission_name)
              MSG_ROLE_ACCESS
            end
          end
        end
      end
    end
  end
end
