# frozen_string_literal: true

class AddCorrelationIdValueUniqueIndexToWorkflowsEvents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  INDEX_NAME = 'i_duo_workflows_events_on_correlation_id'

  def up
    add_concurrent_index :duo_workflows_events, :correlation_id_value, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :duo_workflows_events, :correlation_id_value, name: INDEX_NAME
  end
end
