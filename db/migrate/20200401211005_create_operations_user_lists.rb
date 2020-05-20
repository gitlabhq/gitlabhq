# frozen_string_literal: true

class CreateOperationsUserLists < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :operations_user_lists do |t|
      t.references :project, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone
      t.integer :iid, null: false
      t.string :name, null: false, limit: 255 # rubocop:disable Migration/PreventStrings
      t.text :user_xids, null: false, default: '' # rubocop:disable Migration/AddLimitToTextColumns

      t.index [:project_id, :iid], unique: true
      t.index [:project_id, :name], unique: true
    end
  end
end
