# frozen_string_literal: true

class DropMergeRequestStateIdTempIndex < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'merge_requests_state_id_temp_index'
  INDEX_CONDITION = "state_id IN (2, 3)"

  disable_ddl_transaction!

  def up
    remove_concurrent_index(:merge_requests, :id, where: INDEX_CONDITION, name: INDEX_NAME)
  end

  def down
    add_concurrent_index(:merge_requests, :id, where: INDEX_CONDITION, name: INDEX_NAME)
  end
end
