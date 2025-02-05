# frozen_string_literal: true

class AddCorrelationIdValueLimitToDuoWorkflowsEvents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.9'

  def up
    add_text_limit :duo_workflows_events, :correlation_id_value, 128
  end

  def down
    remove_text_limit :duo_workflows_events, :correlation_id_value
  end
end
