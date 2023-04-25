# frozen_string_literal: true

class CreateSavedReplies < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    create_table :saved_replies do |t|
      t.references :user, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.text :name, null: false, limit: 255
      t.text :content, null: false, limit: 10000

      t.index [:user_id, :name], name: 'index_saved_replies_on_name_text_pattern_ops', unique: true, opclass: { name: :text_pattern_ops }
    end
  end

  def down
    drop_table :saved_replies, if_exists: true
  end
end
