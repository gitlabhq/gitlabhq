# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that prevents usage of `disable_ddl_transaction!`
      # if the only statement being called in the migration is :validate_foreign_key.
      #
      # We do this because PostgreSQL will add an implicit transaction for single
      # statements. So there's no reason to add the disable_ddl_transaction!.
      #
      # This cop was introduced to clarify the need for disable_ddl_transaction!
      # and to avoid bike-shedding and review back-and-forth.
      #
      # @examples
      #
      #   # bad
      #   class SomeMigration < Gitlab::Database::Migration[2.1]
      #     disable_ddl_transaction!
      #     def up
      #       validate_foreign_key :emails, :user_id
      #     end
      #     def down
      #       # no-op
      #     end
      #   end
      #
      #   # good
      #   class SomeMigration < Gitlab::Database::Migration[2.1]
      #     def up
      #       validate_foreign_key :emails, :user_id
      #     end
      #     def down
      #       # no-op
      #     end
      #   end
      class PreventSingleStatementWithDisableDdlTransaction < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = "PostgreSQL will add an implicit transaction for single statements. " \
              "So there's no reason to use `disable_ddl_transaction!`, if you're only " \
              "executing validate_foreign_key."

        def_node_matcher :disable_ddl_transaction?, <<~PATTERN
          (send _ :disable_ddl_transaction! ...)
        PATTERN

        def_node_matcher :validate_foreign_key?, <<~PATTERN
          (send :validate_foreign_key ...)
        PATTERN

        def on_begin(node)
          return unless in_migration?(node)

          disable_ddl_transaction_node = nil

          # Only perform cop if disable_ddl_transaction! is present
          node.each_descendant(:send) do |send_node|
            disable_ddl_transaction_node = send_node if disable_ddl_transaction?(send_node)
          end

          return unless disable_ddl_transaction_node

          # For each migration method, check if :validate_foreign_key is the only statement.
          node.each_descendant(:def) do |def_node|
            break unless [:up, :down, :change].include? def_node.children[0]

            statement_count = 0
            has_validate_foreign_key = false

            def_node.each_descendant(:send) do |send_node|
              has_validate_foreign_key = true if send_node.children[1] == :validate_foreign_key
              statement_count += 1
            end

            if disable_ddl_transaction_node && has_validate_foreign_key && statement_count == 1
              add_offense(disable_ddl_transaction_node, message: MSG)
            end
          end
        end
      end
    end
  end
end
