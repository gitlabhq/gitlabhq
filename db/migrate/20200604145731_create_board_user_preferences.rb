# frozen_string_literal: true

class CreateBoardUserPreferences < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    create_table :board_user_preferences do |t|
      t.bigint :user_id, null: false, index: true
      t.bigint :board_id, null: false, index: true
      t.boolean :hide_labels
      t.timestamps_with_timezone null: false
    end

    add_index :board_user_preferences, [:user_id, :board_id], unique: true
  end

  def down
    drop_table :board_user_preferences
  end
end
