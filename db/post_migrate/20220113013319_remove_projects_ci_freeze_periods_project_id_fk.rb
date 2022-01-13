# frozen_string_literal: true

class RemoveProjectsCiFreezePeriodsProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_freeze_periods, :projects, name: "fk_2e02bbd1a6")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_freeze_periods, :projects, name: "fk_2e02bbd1a6", column: :project_id, target_column: :id, on_delete: "cascade")
  end
end
