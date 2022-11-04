# frozen_string_literal: true

class CreateNamespaceCommitEmails < Gitlab::Database::Migration[2.0]
  def change
    create_table :namespace_commit_emails do |t|
      t.references :user, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.references :namespace, null: false
      t.references :email, null: false
      t.timestamps_with_timezone null: false

      t.index [:user_id, :namespace_id], unique: true
    end
  end
end
