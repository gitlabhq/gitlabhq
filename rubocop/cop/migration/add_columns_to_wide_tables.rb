# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that prevents adding columns to wide tables.
      class AddColumnsToWideTables < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = '`%s` is a wide table with several columns, adding more should be avoided unless absolutely necessary.' \
              ' Consider storing the column in a different table or creating a new one.'

        BLACKLISTED_METHODS = %i[
          add_column
          add_reference
          add_timestamps_with_timezone
        ].freeze

        def on_send(node)
          return unless in_migration?(node)

          method_name = node.children[1]
          table_name = node.children[2]

          return unless offense?(method_name, table_name)

          add_offense(node, location: :selector, message: format(MSG, table_name.value))
        end

        private

        def offense?(method_name, table_name)
          wide_table?(table_name) &&
            BLACKLISTED_METHODS.include?(method_name)
        end

        def wide_table?(table_name)
          table_name && table_name.type == :sym &&
            WIDE_TABLES.include?(table_name.value)
        end
      end
    end
  end
end
