# frozen_string_literal: true

class AddOrganizationIdToEmails < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.4'

  INDEX_NAME = 'index_emails_on_organization_id'

  def up
    with_lock_retries do
      add_column :emails, :organization_id, :bigint, if_not_exists: true
    end

    add_concurrent_index :emails, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :emails, INDEX_NAME

    with_lock_retries do
      remove_column :emails, :organization_id, if_exists: true
    end
  end
end
