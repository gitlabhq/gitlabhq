# frozen_string_literal: true

class AddEmailsConfirmationTokenIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.9'

  # _on_ clause is removed due to existing unique index index_emails_on_confirmation_token
  # which is removed in the next migration
  INDEX_NAME = 'index_emails_confirmation_token'

  # after removing the UNIQUE index, add back as non-unique index for lookups without user_id
  def up
    add_concurrent_index :emails, :confirmation_token, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :emails, INDEX_NAME
  end
end
