# frozen_string_literal: true

class BoardsEpicUserPreferences < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    create_table :boards_epic_user_preferences do |t|
      t.bigint :board_id, null: false
      t.bigint :user_id, null: false
      t.bigint :epic_id, null: false
      t.boolean :collapsed, default: false, null: false
    end

    add_index :boards_epic_user_preferences, :board_id
    add_index :boards_epic_user_preferences, :user_id
    add_index :boards_epic_user_preferences, :epic_id
    add_index :boards_epic_user_preferences, [:board_id, :user_id, :epic_id], unique: true, name: 'index_boards_epic_user_preferences_on_board_user_epic_unique'
  end

  def down
    drop_table :boards_epic_user_preferences
  end
end
