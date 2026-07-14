# frozen_string_literal: true

class AddFkCdRolloutEnvironmentsToCdVersionSets < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    add_concurrent_foreign_key :cd_rollout_environments, :cd_version_sets,
      column: :previous_version_set_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_rollout_environments, column: :previous_version_set_id
    end
  end
end
