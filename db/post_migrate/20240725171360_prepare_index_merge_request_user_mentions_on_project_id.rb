# frozen_string_literal: true

class PrepareIndexMergeRequestUserMentionsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_request_user_mentions_on_project_id'

  def up
    prepare_async_index :merge_request_user_mentions, :project_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :merge_request_user_mentions, INDEX_NAME
  end
end
