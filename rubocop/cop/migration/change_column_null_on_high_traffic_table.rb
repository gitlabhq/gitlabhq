# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class ChangeColumnNullOnHighTrafficTable < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = 'Using `change_column_null` migration helper is risky for high-traffic tables. ' \
              'Please use `add_not_null_constraint` helper instead. ' \
              'For more details check https://docs.gitlab.com/ee/development/database/not_null_constraints.html#not-null-constraints-on-large-tables'

        def on_send(node)
          return unless in_migration?(node)
          return unless node.command?(:change_column_null)

          add_offense(node) if violates?(node)
        end

        private

        def violates?(node)
          table_name = node.first_argument.try(:value)

          return unless table_name

          nullable = node.arguments.third

          # constraint validation only needs to be performed when _adding_ a constraint,
          # not when removing a constraint.
          #
          # rubocop:disable Lint/BooleanSymbol -- Node#type? takes the name of the primitive as a symbol
          return unless nullable&.type?(:false)

          # rubocop:enable Lint/BooleanSymbol

          large_or_over_limit_tables.include?(table_name.to_sym)
        end
      end
    end
  end
end
