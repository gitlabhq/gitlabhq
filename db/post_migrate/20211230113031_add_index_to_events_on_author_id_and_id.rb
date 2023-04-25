# frozen_string_literal: true

class AddIndexToEventsOnAuthorIdAndId < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_events_on_author_id_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :events, [:author_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :events, INDEX_NAME
  end
end
