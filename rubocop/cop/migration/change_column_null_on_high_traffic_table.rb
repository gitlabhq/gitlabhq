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
          table_name = node.arguments.first.try(:value)

          return unless table_name

          high_traffic_tables.include?(table_name.to_sym)
        end
      end
    end
  end
end
