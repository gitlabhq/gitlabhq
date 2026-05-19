# frozen_string_literal: true

class CreateGroupSecretsManagerMaintenanceTasks < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    create_table :group_secrets_manager_maintenance_tasks do |t|
      t.bigint :user_id, null: false
      t.bigint :group_id, null: false
      t.bigint :root_namespace_id, null: false
      t.bigint :organization_id, null: false
      t.datetime_with_timezone :last_processed_at
      t.integer :action, limit: 2, null: false
      t.integer :retry_count, limit: 2, null: false, default: 0

      t.index :group_id,
        unique: true,
        name: 'uniq_gsm_maintenance_tasks_on_group_id'
      t.index :last_processed_at,
        name: 'idx_gsm_maintenance_tasks_on_last_processed_at'
      t.index :root_namespace_id,
        name: 'idx_gsm_maintenance_tasks_on_root_namespace_id'
      t.index :organization_id,
        name: 'idx_gsm_maintenance_tasks_on_organization_id'
    end
  end
end
