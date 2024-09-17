# frozen_string_literal: true

class RemoveSecurityPoliciesActionsAndApprovalSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  def up
    with_lock_retries do
      remove_column :security_policies, :actions
      remove_column :security_policies, :approval_settings
    end
  end

  def down
    with_lock_retries do
      add_column :security_policies, :actions, :jsonb, default: [], null: false, if_not_exists: true
      add_column :security_policies, :approval_settings, :jsonb, default: {}, null: false, if_not_exists: true
    end
  end
end
