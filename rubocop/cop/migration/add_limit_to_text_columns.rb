# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that enforces always adding a limit on text columns
      #
      # Text columns starting with `encrypted_` are very likely used
      # by `attr_encrypted` which controls the text length. Those columns
      # should not add a text limit.
      class AddLimitToTextColumns < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = 'Text columns should always have a limit set (255 is suggested). ' \
          'You can add a limit to a `text` column by using `add_text_limit`'

        def_node_matcher :reverting?, <<~PATTERN
          (def :down ...)
        PATTERN

        def_node_matcher :set_text_limit?, <<~PATTERN
          (send _ :text_limit ...)
        PATTERN

        def_node_matcher :add_text_limit?, <<~PATTERN
          (send _ :add_text_limit ...)
        PATTERN

        def on_def(node)
          return unless in_migration?(node)

          # Don't enforce the rule when on down to keep consistency with existing schema
          return if reverting?(node)

          node.each_descendant(:send) do |send_node|
            next unless text_operation?(send_node)

            # We require a limit for the same table and attribute name
            if text_limit_missing?(node, *table_and_attribute_name(send_node))
              add_offense(send_node, location: :selector)
            end
          end
        end

        private

        def text_operation?(node)
          # Don't complain about text arrays
          return false if array_column?(node)

          modifier = node.children[0]
          migration_method = node.children[1]

          if migration_method == :text
            modifier.type == :lvar
          elsif ADD_COLUMN_METHODS.include?(migration_method)
            modifier.nil? && text_column?(node.children[4])
          end
        end

        def text_column?(column_type)
          column_type.type == :sym && column_type.value == :text
        end

        # For a given node, find the table and attribute this node is for
        #
        # Simple when we have calls to `add_column_XXX` helper methods
        #
        # A little bit more tricky when we have attributes defined as part of
        # a create/change table block:
        # - The attribute name is available on the node
        # - Finding the table name requires to:
        #   * go up
        #   * find the first block the attribute def is part of
        #   * go back down to find the create_table node
        #   * fetch the table name from that node
        def table_and_attribute_name(node)
          migration_method = node.children[1]
          table_name, attribute_name = ''

          if migration_method == :text
            # We are inside a node in a create/change table block
            block_node = node.each_ancestor(:block).first
            create_table_node = block_node
                                  .children
                                  .find { |n| TABLE_METHODS.include?(n.children[1])}

            if create_table_node
              table_name = create_table_node.children[2].value
            else
              # Guard against errors when a new table create/change migration
              # helper is introduced and warn the author so that it can be
              # added in TABLE_METHODS
              table_name = 'unknown'
              add_offense(block_node, message: 'Unknown table create/change helper')
            end

            attribute_name = node.children[2].value
          else
            # We are in a node for one of the ADD_COLUMN_METHODS
            table_name = node.children[2].value
            attribute_name = node.children[3].value
          end

          [table_name, attribute_name]
        end

        # Check if there is an `add_text_limit` call for the provided
        # table and attribute name
        def text_limit_missing?(node, table_name, attribute_name)
          return false if encrypted_attribute_name?(attribute_name)

          limit_found = false

          node.each_descendant(:send) do |send_node|
            if set_text_limit?(send_node)
              limit_found = matching_set_text_limit?(send_node, attribute_name)
            elsif add_text_limit?(send_node)
              limit_found = matching_add_text_limit?(send_node, table_name, attribute_name)
            end

            break if limit_found
          end

          !limit_found
        end

        def matching_set_text_limit?(send_node, attribute_name)
          limit_attribute = send_node.children[2].value

          limit_attribute == attribute_name
        end

        def matching_add_text_limit?(send_node, table_name, attribute_name)
          limit_table = send_node.children[2].value
          limit_attribute = send_node.children[3].value

          limit_table == table_name && limit_attribute == attribute_name
        end

        def encrypted_attribute_name?(attribute_name)
          attribute_name.to_s.start_with?('encrypted_')
        end
      end
    end
  end
end
