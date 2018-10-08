# frozen_string_literal: true

class AddLabelEventEpicColumn < ActiveRecord::Migration
  DOWNTIME = false

  def up
    # When moving from CE to EE, this column may already exist
    return if column_exists?(:resource_label_events, :epic_id)

    add_reference :resource_label_events, :epic, null: true, index: true, foreign_key: { on_delete: :cascade }
  end

  def down
    # epic_id is deleted in db/migrate/20180726172057_create_resource_label_events.rb
  end
end
