# frozen_string_literal: true

class CreateGroupSavedRepliesTable < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '16.9'

  def change
    create_table :group_saved_replies do |t|
      t.references :group, references: :namespaces, null: false,
        foreign_key: { to_table: :namespaces, on_delete: :cascade }, index: true
      t.timestamps_with_timezone null: false
      t.text :name, null: false, limit: 255
      t.text :content, null: false, limit: 10000
    end
  end
end
