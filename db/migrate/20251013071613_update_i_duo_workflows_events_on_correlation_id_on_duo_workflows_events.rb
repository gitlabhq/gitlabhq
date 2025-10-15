# frozen_string_literal: true

class UpdateIDuoWorkflowsEventsOnCorrelationIdOnDuoWorkflowsEvents < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  TABLE_NAME = :duo_workflows_events
  NEW_INDEX_NAME = :i_duo_workflows_events_on_correlation_id_project_id
  OLD_INDEX_NAME = :i_duo_workflows_events_on_correlation_id

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[correlation_id_value project_id],
      unique: true,
      name: NEW_INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      %i[correlation_id_value],
      unique: true,
      name: OLD_INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
