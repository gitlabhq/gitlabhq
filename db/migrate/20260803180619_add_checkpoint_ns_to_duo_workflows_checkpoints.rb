# frozen_string_literal: true

class AddCheckpointNsToDuoWorkflowsCheckpoints < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_duo_wf_checkpoints_checkpoint_ns_limit'

  def up
    add_column :p_duo_workflows_checkpoints, :checkpoint_ns, :text, if_not_exists: true

    add_text_limit :p_duo_workflows_checkpoints, :checkpoint_ns, 255, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_column :p_duo_workflows_checkpoints, :checkpoint_ns, if_exists: true
  end
end
