# frozen_string_literal: true

class AddIndexToCiJobArtifactsForTerraformReports < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_job_artifacts_for_terraform_reports'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_job_artifacts, [:project_id, :id], where: 'file_type = 18', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_NAME
  end
end
