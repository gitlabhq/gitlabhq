# frozen_string_literal: true

class RemoveUsersCiPipelineSchedulesOwnerIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_pipeline_schedules, :users, name: "fk_9ea99f58d2")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_pipeline_schedules, :users, name: "fk_9ea99f58d2", column: :owner_id, target_column: :id, on_delete: :nullify)
  end
end
