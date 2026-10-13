# frozen_string_literal: true

class RemoveEnabledFoundationalFlowsFkFromEnabledFoundationalFlowCheckResults < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  SOURCE_TABLE_NAME = :enabled_foundational_flow_check_results
  TARGET_TABLE_NAME = :enabled_foundational_flows
  COLUMN = :enabled_foundational_flow_id
  FOREIGN_KEY_NAME = :fk_97ace560fa

  def up
    with_lock_retries do
      remove_foreign_key_if_exists SOURCE_TABLE_NAME, TARGET_TABLE_NAME, column: COLUMN,
        name: FOREIGN_KEY_NAME
    end
  end

  def down
    add_concurrent_foreign_key SOURCE_TABLE_NAME, TARGET_TABLE_NAME, column: COLUMN,
      on_delete: :cascade, name: FOREIGN_KEY_NAME
  end
end
