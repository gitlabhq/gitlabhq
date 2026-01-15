# frozen_string_literal: true

class CreateProjectSecretsManagerMaintenanceTasks < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  def up
    create_table :project_secrets_manager_maintenance_tasks do |t|
      t.bigint :user_id, null: false
      t.references :project_secrets_manager,
        index: false,
        foreign_key: { on_delete: :cascade }, null: false
      t.datetime_with_timezone :last_processed_at
      t.integer :action, limit: 2, null: false
      t.integer :retry_count, limit: 2, null: false, default: 0
    end

    add_concurrent_index :project_secrets_manager_maintenance_tasks,
      [:project_secrets_manager_id, :action],
      unique: true,
      name: 'uniq_psm_maintenance_tasks_on_psm_id_and_action'
    add_concurrent_index :project_secrets_manager_maintenance_tasks,
      [:last_processed_at, :retry_count],
      name: 'idx_psm_maintenance_tasks_on_processed_at_retry_count'
  end

  def down
    drop_table :project_secrets_manager_maintenance_tasks
  end
end
