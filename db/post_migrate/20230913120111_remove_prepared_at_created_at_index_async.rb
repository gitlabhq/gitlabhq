# frozen_string_literal: true

class RemovePreparedAtCreatedAtIndexAsync < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_merge_requests_on_id_and_prepared_at'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :merge_requests, name: INDEX_NAME
  end

  def down
    add_concurrent_index :merge_requests, :id, name: INDEX_NAME, where: "prepared_at IS NULL"
  end
end
