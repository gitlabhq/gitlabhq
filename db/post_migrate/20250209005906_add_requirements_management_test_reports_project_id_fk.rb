# frozen_string_literal: true

class AddRequirementsManagementTestReportsProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :requirements_management_test_reports, :projects, column: :project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :requirements_management_test_reports, column: :project_id
    end
  end
end
