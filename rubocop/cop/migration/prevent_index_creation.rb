# frozen_string_literal: true
require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if new indexes are introduced to forbidden tables.
      class PreventIndexCreation < RuboCop::Cop::Cop
        include MigrationHelpers

        FORBIDDEN_TABLES = %i[ci_builds].freeze

        MSG = "Adding new index to #{FORBIDDEN_TABLES.join(", ")} is forbidden, see https://gitlab.com/gitlab-org/gitlab/-/issues/332886"

        def_node_matcher :add_index?, <<~PATTERN
          (send nil? :add_index (sym #forbidden_tables?) ...)
        PATTERN

        def_node_matcher :add_concurrent_index?, <<~PATTERN
          (send nil? :add_concurrent_index (sym #forbidden_tables?) ...)
        PATTERN

        def forbidden_tables?(node)
          FORBIDDEN_TABLES.include?(node)
        end

        def on_def(node)
          return unless in_migration?(node)

          node.each_descendant(:send) do |send_node|
            add_offense(send_node, location: :selector) if offense?(send_node)
          end
        end

        def offense?(node)
          add_index?(node) || add_concurrent_index?(node)
        end
      end
    end
  end
end
