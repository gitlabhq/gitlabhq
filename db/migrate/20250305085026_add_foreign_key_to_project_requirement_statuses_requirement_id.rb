# frozen_string_literal: true

class AddForeignKeyToProjectRequirementStatusesRequirementId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_requirement_compliance_statuses, :compliance_requirements,
      column: :compliance_requirement_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :project_requirement_compliance_statuses, column: :compliance_requirement_id
    end
  end
end
