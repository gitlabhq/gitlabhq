# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that enforces length constraints to string columns
      class AddLimitToStringColumns < RuboCop::Cop::Cop
        include MigrationHelpers

        ADD_COLUMNS_METHODS = %i(add_column add_column_with_default).freeze

        MSG = 'String columns should have a limit constraint. 255 is suggested'.freeze

        def on_def(node)
          return unless in_migration?(node)

          node.each_descendant(:send) do |send_node|
            next unless string_operation?(send_node)

            add_offense(send_node, location: :selector) unless limit_on_string_column?(send_node)
          end
        end

        private

        def string_operation?(node)
          modifier = node.children[0]
          migration_method = node.children[1]

          if migration_method == :string
            modifier.type == :lvar
          elsif ADD_COLUMNS_METHODS.include?(migration_method)
            modifier.nil? && string_column?(node.children[4])
          end
        end

        def string_column?(column_type)
          column_type.type == :sym && column_type.value == :string
        end

        def limit_on_string_column?(node)
          migration_method = node.children[1]

          if migration_method == :string
            limit_present?(node.children)
          elsif ADD_COLUMNS_METHODS.include?(migration_method)
            limit_present?(node)
          end
        end

        def limit_present?(statement)
          !(statement.to_s =~ /:limit/).nil?
        end
      end
    end
  end
end
