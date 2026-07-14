# frozen_string_literal: true

class AddFkCdRolloutEnvironmentsToCdRollouts < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    add_concurrent_foreign_key :cd_rollout_environments, :cd_rollouts,
      column: :rollout_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_rollout_environments, column: :rollout_id
    end
  end
end
