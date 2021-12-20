# frozen_string_literal: true

class ImproveIndexOnEventsForCalendar < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_events_author_id_project_id_action_target_type_created_at'

  def up
    prepare_async_index :events, [:author_id, :project_id, :action, :target_type, :created_at], name: INDEX_NAME
  end

  def down
    unprepare_async_index :events, [:author_id, :project_id, :action, :target_type, :created_at], name: INDEX_NAME
  end
end
