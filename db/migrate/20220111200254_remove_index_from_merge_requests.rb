# frozen_string_literal: true

class RemoveIndexFromMergeRequests < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_requests_on_title'

  def up
    remove_concurrent_index :merge_requests, :title, name: INDEX_NAME
  end

  def down
    add_concurrent_index :merge_requests, :title, name: INDEX_NAME
  end
end
