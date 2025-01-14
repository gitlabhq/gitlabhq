# frozen_string_literal: true

class AddForeignKeyToComplianceControlsStatusesNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_control_compliance_statuses, :namespaces, column: :namespace_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :project_control_compliance_statuses, column: :namespace_id
    end
  end
end
