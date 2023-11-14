# frozen_string_literal: true
require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if new indexes are introduced to forbidden tables.
      class PreventIndexCreation < RuboCop::Cop::Base
        include MigrationHelpers

        FORBIDDEN_TABLES = %i[ci_builds namespaces projects users].freeze

        MSG = "Adding new index to #{FORBIDDEN_TABLES.join(", ")} is forbidden. " \
              "For `ci_builds` see https://gitlab.com/gitlab-org/gitlab/-/issues/332886, " \
              "for `namespaces`, `projects`, and `users` see https://gitlab.com/groups/gitlab-org/-/epics/11543".freeze

        def on_new_investigation
          super
          @forbidden_tables_used = false
        end

        def_node_matcher :add_index?, <<~PATTERN
          (send nil? :add_index ({sym|str} #forbidden_tables?) ...)
        PATTERN

        def_node_matcher :add_concurrent_index?, <<~PATTERN
          (send nil? :add_concurrent_index ({sym|str} #forbidden_tables?) ...)
        PATTERN

        def_node_matcher :forbidden_constant_defined?, <<~PATTERN
          (casgn nil? _ ({sym|str} #forbidden_tables?))
        PATTERN

        def_node_matcher :add_concurrent_index_with_constant?, <<~PATTERN
          (send nil? :add_concurrent_index (const nil? _) ...)
        PATTERN

        def on_casgn(node)
          @forbidden_tables_used = !!forbidden_constant_defined?(node)
        end

        def on_def(node)
          return unless in_migration?(node)

          direction = node.children[0]
          return if direction == :down

          node.each_descendant(:send) do |send_node|
            add_offense(send_node.loc.selector) if offense?(send_node)
          end
        end

        private

        def forbidden_tables?(node)
          FORBIDDEN_TABLES.include?(node.to_sym)
        end

        def offense?(node)
          add_index?(node) || add_concurrent_index?(node) || any_constant_used_with_forbidden_tables?(node)
        end

        def any_constant_used_with_forbidden_tables?(node)
          add_concurrent_index_with_constant?(node) && @forbidden_tables_used
        end
      end
    end
  end
end
