# frozen_string_literal: true

class AddAsyncIndexForEventsFollowedUsers < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_events_for_followed_users'

  def up
    prepare_async_index :events, %I[author_id target_type action id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :events, %I[author_id target_type action id], name: INDEX_NAME
  end
end
