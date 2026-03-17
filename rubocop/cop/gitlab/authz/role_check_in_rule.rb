# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Authz
        # Flags role-based access checks inside policy rules.
        #
        # This includes both:
        # 1. can?(:*_access) calls (e.g., can?(:developer_access))
        # 2. Bare role conditions (e.g., guest, developer, maintainer)
        #
        # We want to move towards a permissions-first model where policies do not
        # directly reason about roles.
        #
        # @example
        #
        #   # bad
        #   rule { can?(:developer_access) }.enable :read_foo
        #   rule { ~can?(:maintainer_access) }.prevent :read_foo
        #   rule { feature_enabled & can?(:developer_access) }.enable :read_foo
        #   rule { guest }.enable :read_code
        #   rule { developer & feature_enabled }.enable :write_foo
        #   rule { ~maintainer }.prevent :admin_foo
        #
        #   # good
        #   rule { can?(:read_foo) }.enable :read_foo
        #
        class RoleCheckInRule < RuboCop::Cop::Base
          ROLE_PERMISSION_MSG = 'Avoid role-based checks (can?(:%<role>s)) in policy rules.'
          ROLE_CONDITION_MSG = 'Avoid role-based conditions (%<role>s) in policy rules.'

          # Role names derived from Gitlab::Access constants
          ROLE_CONDITIONS = %i[
            guest
            planner
            reporter
            security_manager
            developer
            maintainer
            owner
          ].to_set.freeze

          ROLE_PERMISSIONS = %i[
            guest_access
            planner_access
            reporter_access
            security_manager_access
            developer_access
            maintainer_access
            owner_access
          ].to_set.freeze

          # @!method can_with_sym_arg?(node)
          def_node_matcher :can_with_sym_arg?, <<~PATTERN
            (send _ :can? (sym $_))
          PATTERN

          def on_block(node)
            check_rule_block(node)
          end
          alias_method :on_numblock, :on_block

          private

          def check_rule_block(node)
            send_node = node.send_node
            body_node = node.body

            return unless send_node&.send_type?
            return unless send_node.method?(:rule)
            return if body_node.nil?

            find_access_level_can_calls(body_node).each do |can_call|
              sym_node = can_call.first_argument
              add_offense(sym_node, message: format(ROLE_PERMISSION_MSG, role: sym_node.value))
            end

            find_role_condition_sends(body_node).each do |role_send|
              add_offense(role_send, message: format(ROLE_CONDITION_MSG, role: role_send.method_name))
            end
          end

          def find_access_level_can_calls(node)
            node.each_node(:send).filter_map do |send_node|
              can_with_sym_arg?(send_node) do |method_arg|
                next unless ROLE_PERMISSIONS.include?(method_arg)

                send_node
              end
            end
          end

          def find_role_condition_sends(node)
            node.each_node(:send).select do |send_node|
              # Bare role conditions are method calls with no receiver and no arguments
              # e.g., `guest`, `developer`, `maintainer`
              send_node.receiver.nil? &&
                send_node.arguments.empty? &&
                ROLE_CONDITIONS.include?(send_node.method_name)
            end
          end
        end
      end
    end
  end
end
