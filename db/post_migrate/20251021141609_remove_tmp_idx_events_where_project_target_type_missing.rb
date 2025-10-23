# frozen_string_literal: true

class RemoveTmpIdxEventsWhereProjectTargetTypeMissing < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  INDEX_NAME = 'tmp_idx_events_where_project_target_type_missing'

  def up
    prepare_async_index_removal :events, :id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :events, :id, name: INDEX_NAME
  end
end
