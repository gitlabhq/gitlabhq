# frozen_string_literal: true

class CreateEpicListUserPreferences < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    create_table :boards_epic_list_user_preferences do |t|
      t.bigint :user_id, null: false
      t.bigint :epic_list_id, index: true, null: false
      t.timestamps_with_timezone null: false
      t.boolean :collapsed, null: false, default: false
    end

    add_index :boards_epic_list_user_preferences, [:user_id, :epic_list_id], unique: true, name: 'index_epic_board_list_preferences_on_user_and_list'
  end

  def down
    drop_table :boards_epic_list_user_preferences
  end
end
