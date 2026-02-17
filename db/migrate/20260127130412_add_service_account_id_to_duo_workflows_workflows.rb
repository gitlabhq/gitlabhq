# frozen_string_literal: true

class AddServiceAccountIdToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.9'

  INDEX_NAME = 'index_duo_workflows_workflows_on_service_account_id'
  FK_NAME = 'fk_duo_workflows_workflows_service_account_id'

  def up
    with_lock_retries do
      add_column :duo_workflows_workflows, :service_account_id, :bigint, null: true, if_not_exists: true
    end

    add_concurrent_index :duo_workflows_workflows, :service_account_id, name: INDEX_NAME
    add_concurrent_foreign_key :duo_workflows_workflows, :users,
      column: :service_account_id,
      on_delete: :nullify,
      validate: false,
      name: FK_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :duo_workflows_workflows, column: :service_account_id, name: FK_NAME
      remove_column :duo_workflows_workflows, :service_account_id, if_exists: true
    end
  end
end
