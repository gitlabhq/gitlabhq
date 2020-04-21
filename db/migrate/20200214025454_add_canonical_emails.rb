# frozen_string_literal: true

class AddCanonicalEmails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :user_canonical_emails do |t|
        t.timestamps_with_timezone
        t.references :user, index: false, null: false, foreign_key: { on_delete: :cascade }
        t.string :canonical_email, null: false, index: true # rubocop:disable Migration/PreventStrings
      end
    end

    add_index :user_canonical_emails, [:user_id, :canonical_email], unique: true
    add_index :user_canonical_emails, :user_id, unique: true
  end

  def down
    with_lock_retries do
      drop_table(:user_canonical_emails)
    end
  end
end
