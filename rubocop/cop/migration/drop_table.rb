# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if `drop_table` is called in deployment migrations.
      # Calling it in deployment migrations can cause downtimes as there still may be code using the target tables.
      class DropTable < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = <<-MESSAGE.delete("\n").squeeze
          `drop_table` in deployment migrations requires downtime.
          Drop tables in post-deployment migrations instead.
        MESSAGE

        def on_def(node)
          return unless in_deployment_migration?(node)
          return if down_method?(node)

          node.each_descendant(:send) do |send_node|
            next unless offensible?(send_node)

            add_offense(send_node.loc.selector)
          end
        end

        private

        def down_method?(node)
          node.method?(:down)
        end

        def offensible?(node)
          drop_table?(node) || drop_table_in_execute?(node)
        end

        def drop_table?(node)
          node.children[1] == :drop_table
        end

        def drop_table_in_execute?(node)
          execute?(node) && drop_table_in_execute_sql?(node)
        end

        def execute?(node)
          node.children[1] == :execute
        end

        def drop_table_in_execute_sql?(node)
          node.children[2].to_s.match?(/drop\s+table/i)
        end
      end
    end
  end
end
