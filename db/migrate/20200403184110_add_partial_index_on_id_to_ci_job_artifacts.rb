# frozen_string_literal: true

class AddPartialIndexOnIdToCiJobArtifacts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_job_artifacts_file_store_is_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_job_artifacts, :id, where: 'file_store IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_NAME
  end
end
