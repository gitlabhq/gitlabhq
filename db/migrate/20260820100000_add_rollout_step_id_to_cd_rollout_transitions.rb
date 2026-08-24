# frozen_string_literal: true

class AddRolloutStepIdToCdRolloutTransitions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  INDEX_NAME = 'index_cd_rollout_transitions_on_rollout_step_id'

  def up
    add_column :cd_rollout_transitions, :rollout_step_id, :bigint, if_not_exists: true
    add_concurrent_index :cd_rollout_transitions, :rollout_step_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :cd_rollout_transitions, INDEX_NAME
    remove_column :cd_rollout_transitions, :rollout_step_id, if_exists: true
  end
end
