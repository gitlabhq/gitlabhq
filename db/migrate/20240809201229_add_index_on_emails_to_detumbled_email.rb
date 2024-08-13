# frozen_string_literal: true

class AddIndexOnEmailsToDetumbledEmail < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  INDEX_NAME = 'index_emails_on_detumbled_email'

  def up
    add_concurrent_index :emails, :detumbled_email, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :emails, INDEX_NAME
  end
end
