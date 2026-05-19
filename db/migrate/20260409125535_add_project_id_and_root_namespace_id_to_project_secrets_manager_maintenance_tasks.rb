# frozen_string_literal: true

class AddProjectIdAndRootNamespaceIdToProjectSecretsManagerMaintenanceTasks < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  TABLE_NAME = :project_secrets_manager_maintenance_tasks

  def up
    with_lock_retries do
      add_column TABLE_NAME, :project_id, :bigint, if_not_exists: true
      add_column TABLE_NAME, :root_namespace_id, :bigint, if_not_exists: true
      add_column TABLE_NAME, :parent_group_id, :bigint, if_not_exists: true
    end

    add_concurrent_index TABLE_NAME, :project_id,
      unique: true,
      name: 'uniq_psm_maintenance_tasks_on_project_id'
    add_concurrent_index TABLE_NAME, :root_namespace_id,
      name: 'idx_psm_maintenance_tasks_on_root_namespace_id'
    add_concurrent_index TABLE_NAME, :parent_group_id,
      name: 'idx_psm_maintenance_tasks_on_parent_group_id'
  end

  def down
    remove_column TABLE_NAME, :parent_group_id, if_exists: true
    remove_column TABLE_NAME, :root_namespace_id, if_exists: true
    remove_column TABLE_NAME, :project_id, if_exists: true
  end
end
