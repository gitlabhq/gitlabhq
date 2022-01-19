# frozen_string_literal: true

class RemoveRequirementsManagementTestReportsBuildIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_rails_e67d085910'

  def up
    with_lock_retries do
      execute('LOCK ci_builds, requirements_management_test_reports IN ACCESS EXCLUSIVE MODE')
      remove_foreign_key_if_exists(:requirements_management_test_reports, :ci_builds, name: CONSTRAINT_NAME)
    end
  end

  def down
    add_concurrent_foreign_key(:requirements_management_test_reports, :ci_builds, column: :build_id, on_delete: :nullify, name: CONSTRAINT_NAME)
  end
end
