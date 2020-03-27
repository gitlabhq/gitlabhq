# frozen_string_literal: true

class RemoveIndexUsedForScanMigration < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'job_artifacts_secure_reports_temp_index'
  COLUMNS = [:id, :file_type, :job_id, :created_at, :updated_at]

  disable_ddl_transaction!

  def up
    if index_exists?(:ci_job_artifacts, COLUMNS, name: INDEX_NAME)
      remove_concurrent_index(:ci_job_artifacts, COLUMNS, name: INDEX_NAME)
    end
  end

  def down
    add_concurrent_index(:ci_job_artifacts,
                         COLUMNS,
                         name: INDEX_NAME,
                         where: 'file_type BETWEEN 5 AND 8')
  end
end
