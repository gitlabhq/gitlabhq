# frozen_string_literal: true

class AddOrganizationFkToEnabledFoundationalFlowCheckResults < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.11'

  def up
    add_concurrent_foreign_key :enabled_foundational_flow_check_results, :organizations,
      column: :organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :enabled_foundational_flow_check_results, column: :organization_id
    end
  end
end
