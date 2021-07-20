# frozen_string_literal: true
#
class AddCiArtifactsDevopsAdoptionIndex < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  NEW_INDEX = 'index_ci_job_artifacts_on_file_type_for_devops_adoption'

  def up
    add_concurrent_index :ci_job_artifacts, [:file_type, :project_id, :created_at], name: NEW_INDEX, where: 'file_type IN (5,6,8,23)'
  end

  def down
    remove_concurrent_index_by_name :ci_job_artifacts, NEW_INDEX
  end
end
