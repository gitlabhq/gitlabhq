# frozen_string_literal: true

class AddFkCdRolloutStepsToCdRolloutEnvironments < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.3'

  def up
    add_concurrent_foreign_key :cd_rollout_steps, :cd_rollout_environments,
      column: :rollout_environment_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_rollout_steps, column: :rollout_environment_id
    end
  end
end
