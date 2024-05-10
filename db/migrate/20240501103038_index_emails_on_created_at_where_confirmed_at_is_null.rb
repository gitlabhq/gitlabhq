# frozen_string_literal: true

class IndexEmailsOnCreatedAtWhereConfirmedAtIsNull < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  INDEX_NAME = 'index_emails_on_created_at_where_confirmed_at_is_null'

  def up
    add_concurrent_index :emails, :created_at, where: 'confirmed_at IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :emails, name: INDEX_NAME
  end
end
