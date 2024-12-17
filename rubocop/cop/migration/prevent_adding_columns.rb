# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that prevents adding columns to wide tables.
      class PreventAddingColumns < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = <<~MSG
          `%s` is over the limit authorized, adding more should be avoided unless absolutely necessary.
          Consider storing the column in a different table or creating a new one.
          The list of large tables is defined in rubocop/rubocop-migrations.yml.
          See https://docs.gitlab.com/ee/development/database/large_tables_limitations.html
        MSG

        DENYLISTED_METHODS = %i[
          add_column
          add_reference
          add_timestamps_with_timezone
        ].freeze

        MIGRATION_METHODS = %i[change up].freeze

        def on_send(node)
          return unless in_migration?(node)
          return unless in_up?(node)

          method_name = node.children[1]
          table_name = node.children[2]

          return unless offense?(method_name, table_name)

          add_offense(node.loc.selector, message: format(MSG, table_name.value))
        end

        private

        def in_up?(node)
          node.each_ancestor(:def).any? do |def_node|
            MIGRATION_METHODS.include?(def_node.method_name)
          end
        end

        def offense?(method_name, table_name)
          table_matches?(table_name) && DENYLISTED_METHODS.include?(method_name)
        end

        def table_matches?(table_name)
          return false unless valid_table_node?(table_name)

          table_value = table_name.value
          wide_or_over_limit_table?(table_value)
        end

        def wide_or_over_limit_table?(table_value)
          WIDE_TABLES.include?(table_value) || over_limit_tables.include?(table_value)
        end

        def valid_table_node?(table_name)
          table_name && table_name.type == :sym
        end
      end
    end
  end
end
