# frozen_string_literal: true

class AddEmailsUniqueConfirmationTokenPerUser < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.9'

  INDEX_NAME = 'index_emails_on_user_id_and_confirmation_token'

  def up
    add_concurrent_index :emails, [:user_id, :confirmation_token], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :emails, INDEX_NAME
  end
end
