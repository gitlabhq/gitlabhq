# frozen_string_literal: true

class ScheduleIndexToEventsAuthorGroupActionTargetTypeCreatedAt < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  INDEX_NAME = 'index_events_author_id_group_id_action_target_type_created_at'
  COLUMNS = [:author_id, :group_id, :action, :target_type, :created_at]

  def up
    prepare_async_index :events, COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index :events, COLUMNS, name: INDEX_NAME
  end
end
