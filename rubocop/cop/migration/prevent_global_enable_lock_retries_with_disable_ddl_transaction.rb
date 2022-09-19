# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that prevents usage of `enable_lock_retries!` within the `disable_ddl_transaction!` method.
      class PreventGlobalEnableLockRetriesWithDisableDdlTransaction < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = '`enable_lock_retries!` cannot be used with `disable_ddl_transaction!`. Use the `with_lock_retries` helper method to define retriable code blocks.'

        def_node_matcher :enable_lock_retries?, <<~PATTERN
          (send _ :enable_lock_retries! ...)
        PATTERN

        def_node_matcher :disable_ddl_transaction?, <<~PATTERN
          (send _ :disable_ddl_transaction! ...)
        PATTERN

        def on_begin(node)
          return unless in_migration?(node)

          has_enable_lock_retries = false
          has_disable_ddl_transaction = false

          node.each_descendant(:send) do |send_node|
            has_enable_lock_retries = true if enable_lock_retries?(send_node)
            has_disable_ddl_transaction = true if disable_ddl_transaction?(send_node)

            if has_enable_lock_retries && has_disable_ddl_transaction
              add_offense(send_node, message: MSG)
              break
            end
          end
        end
      end
    end
  end
end
