# frozen_string_literal: true

class AddProjectIdForeignKeyToScanResultPolicies < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :scan_result_policies,
      :projects,
      column: :project_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :scan_result_policies, column: :project_id
  end
end
