# frozen_string_literal: true

class AddEpicIdToResourceStateEvents < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  INDEX_NAME = 'index_resource_state_events_on_epic_id'

  def up
    add_column :resource_state_events, :epic_id, :integer
    add_index :resource_state_events, :epic_id, name: INDEX_NAME # rubocop:disable Migration/AddIndex
  end

  def down
    remove_index  :resource_state_events, name: INDEX_NAME # rubocop:disable Migration/RemoveIndex
    remove_column :resource_state_events, :epic_id, :integer
  end
end
