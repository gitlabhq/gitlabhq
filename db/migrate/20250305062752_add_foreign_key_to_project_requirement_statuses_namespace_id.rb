# frozen_string_literal: true

class AddForeignKeyToProjectRequirementStatusesNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_requirement_compliance_statuses, :namespaces, column: :namespace_id,
      on_delete: :restrict
  end

  def down
    with_lock_retries do
      remove_foreign_key :project_requirement_compliance_statuses, column: :namespace_id
    end
  end
end
