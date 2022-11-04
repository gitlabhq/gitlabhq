# frozen_string_literal: true

class AddNamespaceCommitEmailsEmailFk < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :namespace_commit_emails, :emails, column: :email_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :namespace_commit_emails, column: :email_id
    end
  end
end
