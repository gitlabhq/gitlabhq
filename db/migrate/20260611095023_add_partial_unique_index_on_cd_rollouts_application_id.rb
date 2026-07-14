# frozen_string_literal: true

class AddPartialUniqueIndexOnCdRolloutsApplicationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  INDEX_NAME = 'index_cd_rollouts_on_application_id_non_terminal'

  # Enforces one active Rollout per Application. Non-terminal states are
  # pending (0), in_progress (1), and paused (2).
  def up
    add_concurrent_index :cd_rollouts, :application_id,
      unique: true,
      where: 'state IN (0, 1, 2)',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :cd_rollouts, INDEX_NAME
  end
end
