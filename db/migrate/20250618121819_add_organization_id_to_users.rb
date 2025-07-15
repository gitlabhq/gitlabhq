# frozen_string_literal: true

class AddOrganizationIdToUsers < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  DEFAULT_ORGANIZATION_ID = 1
  INDEX_NAME = 'index_users_on_organization_id'

  # rubocop:disable Migration/PreventAddingColumns, Migration/PreventIndexCreation -- required for sharding
  def up
    with_lock_retries do
      add_column :users, :organization_id, :bigint, default: DEFAULT_ORGANIZATION_ID, null: false
    end
    add_concurrent_index :users, :organization_id, name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventAddingColumns, Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :users, INDEX_NAME
    with_lock_retries do
      remove_column :users, :organization_id
    end
  end
end
