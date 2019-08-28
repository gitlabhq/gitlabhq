# frozen_string_literal: true

class AddIndexToCiJobArtifactsOnProjectIdForSecurityReports < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_job_artifacts,
                         :project_id,
                         name: "index_ci_job_artifacts_on_project_id_for_security_reports",
                         where: "file_type IN (5, 6, 7, 8)"
  end

  def down
    remove_concurrent_index :ci_job_artifacts,
                            :project_id,
                            name: "index_ci_job_artifacts_on_project_id_for_security_reports"
  end
end
