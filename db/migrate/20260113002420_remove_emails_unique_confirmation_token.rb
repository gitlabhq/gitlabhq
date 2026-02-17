# frozen_string_literal: true

class RemoveEmailsUniqueConfirmationToken < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.9'

  INDEX_NAME = 'index_emails_on_confirmation_token'

  def up
    remove_concurrent_index_by_name :emails, INDEX_NAME
  end

  def down
    add_concurrent_index :emails, :confirmation_token, unique: true, name: INDEX_NAME
  end
end
