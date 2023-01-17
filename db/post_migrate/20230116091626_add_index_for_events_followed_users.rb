# frozen_string_literal: true

class AddIndexForEventsFollowedUsers < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_events_for_followed_users'

  def up
    add_concurrent_index :events, %I[author_id target_type action id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :events, INDEX_NAME
  end
end
