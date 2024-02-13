# frozen_string_literal: true

class AddPolicyLimitApplicationSetting < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  def up
    with_lock_retries do
      add_column :application_settings, :security_approval_policies_limit, :integer, default: 5, null: false,
        if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :security_approval_policies_limit, if_exists: true
    end
  end
end
