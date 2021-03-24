# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Update existent project update_at column after their repository storage was moved
    class BackfillProjectUpdatedAtAfterRepositoryStorageMove
      def perform(*project_ids)
        updated_repository_storages = Projects::RepositoryStorageMove.select("project_id, MAX(updated_at) as updated_at").where(project_id: project_ids).group(:project_id)

        Project.connection.execute <<-SQL
          WITH repository_storage_cte as #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
            #{updated_repository_storages.to_sql}
          )
          UPDATE projects
          SET updated_at = (repository_storage_cte.updated_at + interval '1 second')
          FROM repository_storage_cte
          WHERE projects.id = repository_storage_cte.project_id AND projects.updated_at <= repository_storage_cte.updated_at
        SQL
      end
    end
  end
end
