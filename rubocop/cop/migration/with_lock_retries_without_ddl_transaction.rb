# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that prevents usage of `with_lock_retries` with `disable_ddl_transaction!`
      class WithLockRetriesWithoutDdlTransaction < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = '`with_lock_retries` cannot be used with disabled DDL transactions (`disable_ddl_transaction!`). ' \
          'Please remove the `disable_ddl_transaction!` call from your migration.'.freeze

        def_node_matcher :disable_ddl_transaction?, <<~PATTERN
        (send _ :disable_ddl_transaction!)
        PATTERN

        def_node_matcher :with_lock_retries?, <<~PATTERN
          (send _ :with_lock_retries)
        PATTERN

        def on_send(node)
          return unless in_migration?(node)
          return unless with_lock_retries?(node)

          node.each_ancestor(:begin) do |begin_node|
            disable_ddl_transaction_node = begin_node.children.find { |n| disable_ddl_transaction?(n) }

            add_offense(node, location: :expression) if disable_ddl_transaction_node
          end
        end
      end
    end
  end
end
