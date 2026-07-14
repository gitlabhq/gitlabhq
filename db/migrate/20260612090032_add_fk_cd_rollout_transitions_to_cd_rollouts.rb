# frozen_string_literal: true

class AddFkCdRolloutTransitionsToCdRollouts < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    add_concurrent_foreign_key :cd_rollout_transitions, :cd_rollouts,
      column: :rollout_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_rollout_transitions, column: :rollout_id
    end
  end
end
