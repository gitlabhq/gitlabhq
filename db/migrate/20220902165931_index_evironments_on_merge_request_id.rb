# frozen_string_literal: true

class IndexEvironmentsOnMergeRequestId < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_environments_on_merge_request_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :environments, :merge_request_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :environments, INDEX_NAME
  end
end
