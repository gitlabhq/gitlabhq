# frozen_string_literal: true

class RemoveProjectsCiUnitTestsProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_unit_tests, :projects, name: "fk_7a8fabf0a8")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_unit_tests, :projects, name: "fk_7a8fabf0a8", column: :project_id, target_column: :id, on_delete: "cascade")
  end
end
