# frozen_string_literal: true

class RemoveStateChangedAtPipelineIdColumn < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_vulnerability_state_transitions_on_pipeline_id'

  def up
    with_lock_retries do
      remove_column :vulnerability_state_transitions, :state_changed_at_pipeline_id, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column :vulnerability_state_transitions, :state_changed_at_pipeline_id, :bigint, if_not_exists: true
    end

    add_concurrent_index :vulnerability_state_transitions, :state_changed_at_pipeline_id, name: INDEX_NAME
  end
end
