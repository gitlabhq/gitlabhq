# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Authz
        # Flags role-based access checks (can?(:*_access)) inside policy rules.
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
        #
        #   # good
        #   rule { can?(:read_foo) }.enable :read_foo
        #
        class RoleCheckInRule < RuboCop::Cop::Base
          MSG = 'Avoid role-based checks (can?(:*_access)) in policy rules.'

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
              add_offense(sym_node)
            end
          end

          def find_access_level_can_calls(node)
            node.each_node(:send).filter_map do |send_node|
              can_with_sym_arg?(send_node) do |method_arg|
                next unless method_arg.to_s.end_with?('_access')

                send_node
              end
            end
          end
        end
      end
    end
  end
end
