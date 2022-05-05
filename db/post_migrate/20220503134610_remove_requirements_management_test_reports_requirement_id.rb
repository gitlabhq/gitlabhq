# frozen_string_literal: true

class RemoveRequirementsManagementTestReportsRequirementId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TARGET_TABLE = :requirements_management_test_reports
  CONSTRAINT_NAME = 'fk_rails_fb3308ad55'

  def up
    with_lock_retries do
      remove_column TARGET_TABLE, :requirement_id
    end
  end

  def down
    unless column_exists?(TARGET_TABLE, :requirement_id)
      with_lock_retries do
        add_column TARGET_TABLE, :requirement_id, :bigint, after: :created_at
      end
    end

    add_concurrent_index TARGET_TABLE, :requirement_id,
      name: :index_requirements_management_test_reports_on_requirement_id

    add_concurrent_foreign_key TARGET_TABLE, :requirements,
      column: :requirement_id, name: CONSTRAINT_NAME, on_delete: :cascade
  end
end
