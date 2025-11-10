# frozen_string_literal: true

class DeleteOrphanedClusters < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  GROUP_TYPE = 2
  PROJECT_TYPE = 3

  def up
    define_batchable_model(:clusters).where(project_id: nil, group_id: nil).each_batch(of: 100) do |batch|
      associated_projects = define_batchable_model(:cluster_projects).where('clusters.id = cluster_projects.cluster_id')
      associated_groups = define_batchable_model(:cluster_groups).where('clusters.id = cluster_groups.cluster_id')

      batch
        .where(cluster_type: PROJECT_TYPE, project_id: nil)
        .where('NOT EXISTS (?)', associated_projects)
        .delete_all

      batch
        .where(cluster_type: GROUP_TYPE, group_id: nil)
        .where('NOT EXISTS (?)', associated_groups)
        .delete_all
    end
  end

  def down
    # No-op
  end
end
