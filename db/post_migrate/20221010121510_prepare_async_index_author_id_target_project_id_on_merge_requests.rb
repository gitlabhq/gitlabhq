# frozen_string_literal: true

class PrepareAsyncIndexAuthorIdTargetProjectIdOnMergeRequests < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_merge_requests_on_author_id_and_target_project_id'

  disable_ddl_transaction!

  def up
    prepare_async_index :merge_requests, %i[author_id target_project_id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :merge_requests, %i[author_id target_project_id], name: INDEX_NAME
  end
end
