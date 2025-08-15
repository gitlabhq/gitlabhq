# frozen_string_literal: true

class DropIndexMergeRequestsOnTitleTrigramOnAllInstances < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  TABLE_NAME = :merge_requests
  INDEX_NAME = :index_merge_requests_on_title_trigram

  def up
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :title,
      name: INDEX_NAME,
      using: 'gin',
      opclass: { title: 'gin_trgm_ops' }

    with_lock_retries do
      execute <<~SQL
        ALTER INDEX #{INDEX_NAME} SET ( fastupdate = false ) ;
      SQL
    end
  end
end
