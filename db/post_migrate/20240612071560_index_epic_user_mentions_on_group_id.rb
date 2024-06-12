# frozen_string_literal: true

class IndexEpicUserMentionsOnGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_epic_user_mentions_on_group_id'

  def up
    add_concurrent_index :epic_user_mentions, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :epic_user_mentions, INDEX_NAME
  end
end
