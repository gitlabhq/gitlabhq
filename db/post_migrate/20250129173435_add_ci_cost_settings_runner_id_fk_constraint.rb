# frozen_string_literal: true

class AddCiCostSettingsRunnerIdFkConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_cost_settings
  TARGET_TABLE_NAME = :instance_type_ci_runners_e59bb2812d
  COLUMN_NAME = :runner_id
  FK_CONSTRAINT_NAME = 'fk_9e5e051839'

  def up
    add_concurrent_foreign_key SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
      name: FK_CONSTRAINT_NAME, column: COLUMN_NAME, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists SOURCE_TABLE_NAME, TARGET_TABLE_NAME, name: FK_CONSTRAINT_NAME
    end
  end
end
