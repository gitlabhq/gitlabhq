# frozen_string_literal: true

class DropUserCanonicalEmailsTable < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    remove_foreign_key_if_exists :user_canonical_emails, column: :user_id, reverse_lock_order: true
    drop_table :user_canonical_emails, if_exists: true
  end

  def down
    create_table :user_canonical_emails do |t|
      t.timestamps_with_timezone
      t.references :user, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.string :canonical_email, null: false, index: true
    end

    add_index :user_canonical_emails, [:user_id, :canonical_email], unique: true
    add_index :user_canonical_emails, :user_id, unique: true
  end
end
