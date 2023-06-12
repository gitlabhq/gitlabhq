# frozen_string_literal: true

class AddFkToProjectsComplianceStandardsAdherenceOnProjectId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_compliance_standards_adherence, :projects, column: :project_id,
      on_delete: :cascade, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :project_compliance_standards_adherence, column: :project_id
    end
  end
end
