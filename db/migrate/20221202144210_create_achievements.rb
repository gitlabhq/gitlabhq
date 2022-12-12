# frozen_string_literal: true

class CreateAchievements < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table :achievements do |t|
      t.references :namespace,
                   null: false,
                   index: false,
                   foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.text :name, null: false, limit: 255
      t.text :avatar, limit: 255
      t.text :description, limit: 1024
      t.boolean :revokeable, default: false, null: false
      t.index 'namespace_id, LOWER(name)', unique: true
    end
  end

  def down
    drop_table :achievements
  end
end
