# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if columns are added in a way that doesn't require
      # downtime.
      class AddColumnWithDefault < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = '`add_column_with_default` without `allow_null: true` may cause prolonged lock situations and downtime, ' \
          'see https://gitlab.com/gitlab-org/gitlab/issues/38060'.freeze

        def_node_matcher :add_column_with_default?, <<~PATTERN
          (send _ :add_column_with_default $_ ... (hash $...))
        PATTERN

        def on_send(node)
          return unless in_migration?(node)

          add_column_with_default?(node) do |table, options|
            add_offense(node, location: :selector) if offensive?(table, options)
          end
        end

        private

        def offensive?(table, options)
          table_blacklisted?(table) && !nulls_allowed?(options)
        end

        def nulls_allowed?(options)
          options.find { |opt| opt.key.value == :allow_null && opt.value.true_type? }
        end

        def table_blacklisted?(symbol)
          symbol && symbol.type == :sym &&
            BLACKLISTED_TABLES.include?(symbol.children[0])
        end
      end
    end
  end
end
