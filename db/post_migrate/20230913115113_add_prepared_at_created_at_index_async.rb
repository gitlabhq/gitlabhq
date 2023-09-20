# frozen_string_literal: true

class AddPreparedAtCreatedAtIndexAsync < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_requests_id_created_at_prepared_at'

  def up
    add_concurrent_index :merge_requests, [:created_at, :id], name: INDEX_NAME, where: "prepared_at IS NULL"
  end

  def down
    remove_concurrent_index_by_name :merge_requests, INDEX_NAME
  end
end
