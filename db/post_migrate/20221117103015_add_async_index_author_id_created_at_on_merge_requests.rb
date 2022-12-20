# frozen_string_literal: true

class AddAsyncIndexAuthorIdCreatedAtOnMergeRequests < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_merge_requests_on_author_id_and_created_at'

  def up
    prepare_async_index :merge_requests, %i[author_id created_at], name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :merge_requests, INDEX_NAME
  end
end
