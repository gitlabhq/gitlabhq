# frozen_string_literal: true

class AddMutuallyExclusiveUserAndConsumerConstraintToAiFlowTriggers < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_ai_flow_triggers_user_consumer_mutually_exclusive'

  def up
    add_multi_column_not_null_constraint(
      :ai_flow_triggers,
      :user_id,
      :ai_catalog_item_consumer_id,
      operator: '<=',
      constraint_name: CONSTRAINT_NAME
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      :ai_flow_triggers,
      :user_id,
      :ai_catalog_item_consumer_id,
      constraint_name: CONSTRAINT_NAME
    )
  end
end
