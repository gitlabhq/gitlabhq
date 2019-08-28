# frozen_string_literal: true

class CreateListUserPreferences < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :list_user_preferences do |t|
      t.references :user, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.references :list, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.boolean :collapsed
    end

    add_index :list_user_preferences, [:user_id, :list_id], unique: true
  end
end
