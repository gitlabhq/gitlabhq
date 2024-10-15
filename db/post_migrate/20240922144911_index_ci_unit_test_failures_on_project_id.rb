# frozen_string_literal: true

class IndexCiUnitTestFailuresOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_unit_test_failures_on_project_id'

  def up
    add_concurrent_index :ci_unit_test_failures, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_unit_test_failures, INDEX_NAME
  end
end
