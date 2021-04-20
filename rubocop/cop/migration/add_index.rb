# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if indexes are added in a concurrent manner.
      class AddIndex < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = '`add_index` requires downtime, use `add_concurrent_index` instead'

        def on_def(node)
          return unless in_migration?(node)

          new_tables = []

          node.each_descendant(:send) do |send_node|
            first_arg = first_argument(send_node)

            # The first argument of "create_table" / "add_index" is the table
            # name.
            new_tables << first_arg if create_table?(send_node)

            next if method_name(send_node) != :add_index

            # Using "add_index" is fine for newly created tables as there's no
            # data in these tables yet.
            next if new_tables.include?(first_arg)

            add_offense(send_node, location: :selector)
          end
        end

        def create_table?(node)
          method_name(node) == :create_table
        end

        def method_name(node)
          node.children[1]
        end

        def first_argument(node)
          node.children[2] ? node.children[0] : nil
        end
      end
    end
  end
end
