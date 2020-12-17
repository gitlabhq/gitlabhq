# frozen_string_literal: true

class AddIterationIdIndexToBoardsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_boards_on_iteration_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :boards, :iteration_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :boards, :iteration_id, name: INDEX_NAME
  end
end
