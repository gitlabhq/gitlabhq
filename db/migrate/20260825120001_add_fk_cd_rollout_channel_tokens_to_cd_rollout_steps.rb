# frozen_string_literal: true

class AddFkCdRolloutChannelTokensToCdRolloutSteps < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  def up
    add_concurrent_foreign_key :cd_rollout_channel_tokens, :cd_rollout_steps,
      column: :rollout_step_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_rollout_channel_tokens, column: :rollout_step_id
    end
  end
end
