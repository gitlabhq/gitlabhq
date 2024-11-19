# frozen_string_literal: true
require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # add_reference can only be used with newly created tables.
      # Additionally, the cop here checks that we create an index for the foreign key, too.
      class AddReference < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = '`add_reference` requires downtime for existing tables, use `add_concurrent_foreign_key` instead. When used for new tables, `index: true` or `index: { options... } is required.`'

        def on_def(node)
          return unless in_migration?(node)

          new_tables = []

          node.each_descendant(:send) do |send_node|
            first_arg = first_argument(send_node)

            # The first argument of "create_table" / "add_reference" is the table
            # name.
            new_tables << first_arg if create_table?(send_node)

            next if method_name(send_node) != :add_reference

            # Using "add_reference" is fine for newly created tables as there's no
            # data in these tables yet.
            if existing_table?(new_tables, first_arg)
              add_offense(send_node.loc.selector)
            end

            # We require an index on the foreign key column.
            if index_missing?(node)
              add_offense(send_node.loc.selector)
            end
          end
        end

        private

        def existing_table?(new_tables, table)
          !new_tables.include?(table)
        end

        def create_table?(node)
          method_name(node) == :create_table
        end

        def method_name(node)
          node.children[1]
        end

        def first_argument(node)
          node.children[2]
        end

        def index_missing?(node)
          opts = node.children.last

          return true if opts && opts.type == :hash

          index_present = false

          opts.each_node(:pair) do |pair|
            index_present ||= index_enabled?(pair)
          end

          !index_present
        end

        def index_enabled?(pair)
          return unless hash_key_type(pair) == :sym
          return unless hash_key_name(pair) == :index

          index = pair.children[1]

          index.true_type? || index.hash_type?
        end

        def hash_key_type(pair)
          pair.children[0].type
        end

        def hash_key_name(pair)
          pair.children[0].children[0]
        end
      end
    end
  end
end
