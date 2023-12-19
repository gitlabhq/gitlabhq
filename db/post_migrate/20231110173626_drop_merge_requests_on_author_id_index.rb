# frozen_string_literal: true

class DropMergeRequestsOnAuthorIdIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  INDEX_NAME = 'index_merge_requests_on_author_id'
  TABLE_NAME = :merge_requests

  def up
    # Duplicated index. This index is covered by +index_merge_requests_on_author_id_and_created_at+
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :author_id, name: INDEX_NAME
  end
end
