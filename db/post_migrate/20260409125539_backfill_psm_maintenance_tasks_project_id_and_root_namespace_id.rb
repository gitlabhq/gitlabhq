# frozen_string_literal: true

class BackfillPsmMaintenanceTasksProjectIdAndRootNamespaceId < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_local
  milestone '19.0'

  BATCH_SIZE = 100

  def up
    define_batchable_model('project_secrets_manager_maintenance_tasks').each_batch(of: BATCH_SIZE) do |batch|
      execute(<<~SQL)
        UPDATE project_secrets_manager_maintenance_tasks
        SET project_id = psm.project_id,
            root_namespace_id = n.traversal_ids[1],
            parent_group_id = p.namespace_id
        FROM project_secrets_managers psm
        JOIN projects p ON p.id = psm.project_id
        JOIN namespaces n ON n.id = p.namespace_id
        WHERE psm.id = project_secrets_manager_maintenance_tasks.project_secrets_manager_id
        AND project_secrets_manager_maintenance_tasks.id IN (#{batch.select(:id).to_sql})
      SQL
    end
  end

  def down
    # no-op - cannot rollback data changes
  end
end
