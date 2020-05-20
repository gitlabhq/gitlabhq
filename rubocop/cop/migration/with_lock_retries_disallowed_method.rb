# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class WithLockRetriesDisallowedMethod < RuboCop::Cop::Cop
        include MigrationHelpers

        ALLOWED_MIGRATION_METHODS = %i[
          create_table
          drop_table
          add_foreign_key
          remove_foreign_key
          add_column
          remove_column
          execute
          change_column_default
          remove_foreign_key_if_exists
          remove_foreign_key_without_error
          table_exists?
          index_exists_by_name?
          foreign_key_exists?
          index_exists?
          column_exists?
        ].sort.freeze

        MSG = "The method is not allowed to be called within the `with_lock_retries` block, the only allowed methods are: #{ALLOWED_MIGRATION_METHODS.join(', ')}"

        def_node_matcher :send_node?, <<~PATTERN
        send
        PATTERN

        def on_block(node)
          block_body = node.body

          return unless in_migration?(node)
          return unless block_body
          return unless node.method_name == :with_lock_retries

          if send_node?(block_body)
            check_node(block_body)
          else
            block_body.children.each { |n| check_node(n) }
          end
        end

        def check_node(node)
          return unless send_node?(node)

          name = node.children[1]
          add_offense(node, location: :expression) unless ALLOWED_MIGRATION_METHODS.include?(name)
        end
      end
    end
  end
end
