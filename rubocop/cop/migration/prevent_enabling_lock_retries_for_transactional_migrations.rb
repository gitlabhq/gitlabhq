# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Prevents usage of `enable_lock_retries!` for transactional migrations.
      #
      # @example
      #
      #   # bad
      #   class MyMigration < Gitlab::Database::Migration[2.2]
      #     milestone '18.0'
      #     enable_lock_retries!
      #
      #     def change
      #       add_column :users, :column_id, :smallint
      #     end
      #   end
      #
      #   # good
      #   class MyMigration < Gitlab::Database::Migration[2.2]
      #     milestone '18.0'
      #
      #     def change
      #       add_column :users, :column_id, :smallint
      #     end
      #   end
      class PreventEnablingLockRetriesForTransactionalMigrations < RuboCop::Cop::Base
        include MigrationHelpers

        URL = 'https://docs.gitlab.com/development/migration_style_guide/#transactional-migrations'
        MSG = 'Avoid using `enable_lock_retries! for transactional migrations`. The lock-retry mechanism ' \
          "is enforced by default. Check #{URL} for more details.".freeze

        RESTRICT_ON_SEND = %i[enable_lock_retries!].freeze

        # @!method enable_lock_retries?(node)
        def_node_matcher :enable_lock_retries?, <<~PATTERN
          `$(send nil? :enable_lock_retries!)
        PATTERN

        def on_send(node)
          add_offense(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
