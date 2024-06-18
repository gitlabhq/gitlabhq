# frozen_string_literal: true

class AddTrigramIndexOnEmailForEmails < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_emails_on_email_trigram'

  def up
    return if Gitlab.com_except_jh?

    add_concurrent_index :emails, :email, name: INDEX_NAME, using: :gin, opclass: { email: :gin_trgm_ops }
  end

  def down
    return if Gitlab.com_except_jh?

    remove_concurrent_index_by_name :emails, INDEX_NAME
  end
end
