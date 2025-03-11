# frozen_string_literal: true

class AddMergeRequestUserMentionsProjectIdIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  INDEX_NAME = 'index_merge_request_user_mentions_on_project_id'

  def up
    add_concurrent_index :merge_request_user_mentions, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_user_mentions, INDEX_NAME
  end
end
