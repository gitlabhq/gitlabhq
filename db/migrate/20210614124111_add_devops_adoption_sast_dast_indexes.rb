# frozen_string_literal: true

class AddDevopsAdoptionSastDastIndexes < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_SAST = 'index_ci_job_artifacts_sast_for_devops_adoption'
  INDEX_DAST = 'index_ci_job_artifacts_dast_for_devops_adoption'

  def up
    add_concurrent_index :ci_job_artifacts, [:project_id, :created_at], where: "file_type = 5", name: INDEX_SAST
    add_concurrent_index :ci_job_artifacts, [:project_id, :created_at], where: "file_type = 8", name: INDEX_DAST
  end

  def down
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_SAST
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_DAST
  end
end
