# frozen_string_literal: true

class AddOrganizationIdToSecurityPolicySettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  INDEX_NAME = 'index_security_policy_settings_on_organization_id'

  def up
    with_lock_retries do
      add_column :security_policy_settings, :organization_id, :bigint, if_not_exists: true
    end

    add_concurrent_index :security_policy_settings, :organization_id, unique: true, name: INDEX_NAME
    add_concurrent_foreign_key :security_policy_settings, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :security_policy_settings, column: :organization_id
    remove_concurrent_index_by_name :security_policy_settings, INDEX_NAME

    with_lock_retries do
      remove_column :security_policy_settings, :organization_id, if_exists: true
    end
  end
end
