# frozen_string_literal: true

class AddOrganizationIdToProjectSecretsManagerMaintenanceTasks < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def change
    add_column :project_secrets_manager_maintenance_tasks, :organization_id, :bigint
  end
end
