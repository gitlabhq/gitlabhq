# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Prevents adding new foreign key relationships to high-cardinality CI tables.
      # More details can be found in https://gitlab.com/gitlab-org/gitlab/-/issues/566954
      #
      # @example
      #   # bad
      #   class AddForeignKeyToBuilds < Gitlab::Database::Migration[2.1]
      #     def up
      #       add_concurrent_partitioned_foreign_key :some_table, :p_ci_builds, column: :build_id
      #     end
      #   end
      #
      #   # good
      #   class AddForeignKeyToProjects < Gitlab::Database::Migration[2.1]
      #     def up
      #       add_concurrent_partitioned_foreign_key :some_table, :projects, column: :project_id
      #     end
      #   end
      class PreventForeignKeyCreation < RuboCop::Cop::Base
        FORBIDDEN_TABLES = [
          :p_ci_builds,
          :p_ci_job_artifacts
        ].freeze

        MSG = "Adding new foreign key relationships to some CI tables is forbidden due to high cardinality concerns. " \
          "This restriction is temporary while we address CI growth rate. " \
          "See https://gitlab.com/gitlab-org/gitlab/-/issues/566954 for more details"

        def on_new_investigation
          super
          @forbidden_tables_used = false
        end

        # @!method add_concurrent_partitioned_foreign_key?(node)
        def_node_matcher :add_concurrent_partitioned_foreign_key?, <<~PATTERN
          (send nil? :add_concurrent_partitioned_foreign_key _ ({sym|str} #forbidden_tables?) ...)
        PATTERN

        # @!method forbidden_constant_defined?(node)
        def_node_matcher :forbidden_constant_defined?, <<~PATTERN
          (casgn nil? _ ({sym|str} #forbidden_tables?))
        PATTERN

        # @!method add_concurrent_partitioned_foreign_key_with_constant?(node)
        def_node_matcher :add_concurrent_partitioned_foreign_key_with_constant?, <<~PATTERN
          (send nil? :add_concurrent_partitioned_foreign_key _ (const nil? _) ...)
        PATTERN

        def on_casgn(node)
          @forbidden_tables_used ||= !!forbidden_constant_defined?(node)
        end

        def on_def(node)
          return unless in_migration?(node)

          node.each_descendant(:send) do |send_node|
            add_offense(send_node.loc.selector) if offense?(send_node)
          end
        end

        private

        def in_migration?(node)
          %i[up change].include?(node.method_name)
        end

        def forbidden_tables?(node)
          FORBIDDEN_TABLES.include?(node.to_sym)
        end

        def offense?(node)
          return true if add_concurrent_partitioned_foreign_key?(node)
          return true if @forbidden_tables_used && add_concurrent_partitioned_foreign_key_with_constant?(node)

          false
        end
      end
    end
  end
end
