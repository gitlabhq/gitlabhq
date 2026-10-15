# frozen_string_literal: true

class ReplaceDuoWorkflowsServiceAccountIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.6'

  TABLE_NAME = :duo_workflows_workflows
  NEW_INDEX_NAME = 'idx_duo_workflows_on_service_account_trigger_and_id'
  OLD_INDEX_NAME = 'index_duo_workflows_workflows_on_service_account_id'

  def up
    add_concurrent_index TABLE_NAME, %i[service_account_id trigger_flow_trigger_id id],
      name: NEW_INDEX_NAME, where: 'service_account_id IS NOT NULL'

    remove_concurrent_index_by_name TABLE_NAME, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :service_account_id, name: OLD_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, NEW_INDEX_NAME
  end
end
