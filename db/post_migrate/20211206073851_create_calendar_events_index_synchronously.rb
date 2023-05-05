# frozen_string_literal: true

class CreateCalendarEventsIndexSynchronously < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_events_author_id_project_id_action_target_type_created_at'

  def up
    add_concurrent_index :events, [:author_id, :project_id, :action, :target_type, :created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :events, INDEX_NAME
  end
end
