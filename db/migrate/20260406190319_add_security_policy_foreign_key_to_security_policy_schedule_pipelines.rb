# frozen_string_literal: true

class AddSecurityPolicyForeignKeyToSecurityPolicySchedulePipelines < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  def up
    add_concurrent_foreign_key :security_policy_schedule_pipelines, :security_policies,
      column: :security_policy_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :security_policy_schedule_pipelines, column: :security_policy_id
    end
  end
end
