# frozen_string_literal: true

class AddShardingKeyIndexOnCommitUserMentions < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_commit_user_mentions_on_namespace_id'

  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_concurrent_index :commit_user_mentions, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :commit_user_mentions, INDEX_NAME
  end
end
