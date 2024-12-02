# frozen_string_literal: true

class AddOrganizationIdToPersonalAccessTokens < Gitlab::Database::Migration[2.2]
  DEFAULT_ORGANIZATION_ID = 1
  INDEX_NAME = 'index_personal_access_tokens_on_organization_id'
  milestone '17.4'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :personal_access_tokens, :organization_id, :bigint, default: DEFAULT_ORGANIZATION_ID, null: false,
        if_not_exists: true
    end
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    add_concurrent_index :personal_access_tokens, :organization_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
    add_concurrent_foreign_key :personal_access_tokens, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    remove_column :personal_access_tokens, :organization_id
    remove_concurrent_index :personal_access_tokens, :organization_id, name: INDEX_NAME
    remove_foreign_key_if_exists :personal_access_tokens, column: :organization_id
  end
end
