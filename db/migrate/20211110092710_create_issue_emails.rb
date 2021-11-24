# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateIssueEmails < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    create_table :issue_emails do |t|
      t.references :issue, index: true, null: false, unique: true, foreign_key: { on_delete: :cascade }
      t.text :email_message_id, null: false, limit: 1000

      t.index :email_message_id
    end
  end

  def down
    drop_table :issue_emails
  end
end
