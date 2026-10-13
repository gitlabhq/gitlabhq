# frozen_string_literal: true

class AddShardingKeyCheckConstraintToAiFlowTriggers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  CONSTRAINT_NAME = 'check_ai_flow_triggers_project_or_group'

  def up
    add_multi_column_not_null_constraint :ai_flow_triggers, :project_id, :group_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_multi_column_not_null_constraint :ai_flow_triggers, :project_id, :group_id, constraint_name: CONSTRAINT_NAME
  end
end
