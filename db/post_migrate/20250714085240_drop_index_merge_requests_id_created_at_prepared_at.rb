# frozen_string_literal: true

class DropIndexMergeRequestsIdCreatedAtPreparedAt < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  TABLE_NAME = :merge_requests
  INDEX_NAME = :index_merge_requests_id_created_at_prepared_at

  def up
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, [:created_at, :id], name: INDEX_NAME, where: 'prepared_at IS NULL'
  end
end
