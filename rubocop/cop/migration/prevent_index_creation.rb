# frozen_string_literal: true
require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Adding indexes to certain high traffic tables may cause problems,
      # and caution should be exercised when doing it.
      # The goal of this rule is raise awareness and start a discussion.
      # More details can be found in
      #   - https://gitlab.com/gitlab-org/gitlab/-/issues/332886
      #   - https://gitlab.com/groups/gitlab-org/-/epics/11543
      #   - https://gitlab.com/gitlab-org/gitlab/-/issues/460799
      class PreventIndexCreation < RuboCop::Cop::Base
        include MigrationHelpers

        # NOTE: Other tables are prevented by this cop via `table_size:`
        FORBIDDEN_TABLES = [
          :ci_builds,               # Too many indexes + frequently accessed
          :namespaces,              # Too many indexes + frequently accessed
          :projects,                # Too many indexes + frequently accessed
          :users,                   # Too many indexes + frequently accessed
          :merge_requests,          # Too many indexes + frequently accessed
          :project_statistics,      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154487
          :issues,                  # Too many indexes + frequently accessed
          :issue_search_data,       # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154487
          :packages_packages,       # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154487
          :sbom_occurrences,        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154487
          :deployments              # Too many indexes + frequently accessed
        ].freeze

        MSG = "Adding new index to certain tables is forbidden. See " \
              "https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/cop/migration/prevent_index_creation.rb " \
              "for more details"

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

        def_node_matcher :prepare_async_index?, <<~PATTERN
          (send nil? :prepare_async_index ({sym|str} #forbidden_tables?) ...)
        PATTERN

        def_node_matcher :forbidden_constant_defined?, <<~PATTERN
          (casgn nil? _ ({sym|str} #forbidden_tables?))
        PATTERN

        def_node_matcher :add_concurrent_index_with_constant?, <<~PATTERN
          (send nil? :add_concurrent_index (const nil? _) ...)
        PATTERN

        def_node_matcher :prepare_async_index_with_constant?, <<~PATTERN
          (send nil? :prepare_async_index (const nil? _) ...)
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
          FORBIDDEN_TABLES.include?(node.to_sym) || large_or_over_limit_tables.include?(node.to_sym)
        end

        def offense?(node)
          add_index?(node) ||
            add_concurrent_index?(node) ||
            prepare_async_index?(node) ||
            any_constant_used_with_forbidden_tables?(node)
        end

        def any_constant_used_with_forbidden_tables?(node)
          @forbidden_tables_used && (
            add_concurrent_index_with_constant?(node) || prepare_async_index_with_constant?(node)
          )
        end
      end
    end
  end
end
