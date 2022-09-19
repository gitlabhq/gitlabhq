# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that enforces using text instead of the string data type
      class PreventStrings < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = 'Do not use the `string` data type, use `text` instead. ' \
          'Updating limits on strings requires downtime. This can be avoided ' \
          'by using `text` and adding a limit with `add_text_limit`'

        def_node_matcher :reverting?, <<~PATTERN
          (def :down ...)
        PATTERN

        def on_def(node)
          return unless in_migration?(node)

          # Don't enforce the rule when on down to keep consistency with existing schema
          return if reverting?(node)

          node.each_descendant(:send) do |send_node|
            next unless string_operation?(send_node)

            add_offense(send_node.loc.selector)
          end
        end

        private

        def string_operation?(node)
          # Don't complain about string arrays
          return false if array_column?(node)

          modifier = node.children[0]
          migration_method = node.children[1]

          if migration_method == :string
            modifier.type == :lvar
          elsif ADD_COLUMN_METHODS.include?(migration_method)
            modifier.nil? && string_column?(node.children[4])
          end
        end

        def string_column?(column_type)
          column_type.type == :sym && column_type.value == :string
        end
      end
    end
  end
end
