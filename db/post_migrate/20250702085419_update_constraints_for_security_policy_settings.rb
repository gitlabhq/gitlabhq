# frozen_string_literal: true

class UpdateConstraintsForSecurityPolicySettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  INDEX_NAME = 'index_security_policy_settings_on_singleton'
  CHECK_CONSTRAINT_NAME = 'check_singleton'

  def up
    with_lock_retries do
      change_column_null :security_policy_settings, :organization_id, false
    end

    add_concurrent_foreign_key :security_policy_settings, :namespaces, column: :csp_namespace_id, on_delete: :nullify
    remove_check_constraint :security_policy_settings, CHECK_CONSTRAINT_NAME
    remove_concurrent_index_by_name :security_policy_settings, INDEX_NAME
  end

  def down
    with_lock_retries do
      change_column_null :security_policy_settings, :organization_id, true
    end

    remove_foreign_key_if_exists :security_policy_settings, column: :csp_namespace_id
    add_check_constraint :security_policy_settings, "(singleton IS TRUE)", CHECK_CONSTRAINT_NAME
    add_concurrent_index :security_policy_settings, :singleton, unique: true, name: INDEX_NAME
  end
end
