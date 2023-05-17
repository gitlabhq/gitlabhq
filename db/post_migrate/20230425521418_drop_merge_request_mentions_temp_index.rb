# frozen_string_literal: true

class DropMergeRequestMentionsTempIndex < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'merge_request_mentions_temp_index'
  INDEX_CONDITION = "description like '%@%' OR title like '%@%'"

  disable_ddl_transaction!

  def up
    remove_concurrent_index(:merge_requests, :id, where: INDEX_CONDITION, name: INDEX_NAME)
  end

  def down
    add_concurrent_index(:merge_requests, :id, where: INDEX_CONDITION, name: INDEX_NAME)
  end
end
