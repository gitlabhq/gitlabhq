# frozen_string_literal: true

class SyncRemoveIndexEventsOnAuthorId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = "index_events_on_author_id_and_created_at_merge_requests"

  def up
    remove_concurrent_index_by_name :events, name: INDEX_NAME
  end

  def down
    add_concurrent_index :events,
      [:author_id, :created_at],
      name: INDEX_NAME,
      where: "(target_type = 'MergeRequest')"
  end
end
