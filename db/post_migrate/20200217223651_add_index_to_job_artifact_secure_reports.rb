# frozen_string_literal: true

class AddIndexToJobArtifactSecureReports < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'job_artifacts_secure_reports_temp_index'
  PARTIAL_FILTER = "file_type BETWEEN 5 AND 8"

  disable_ddl_transaction!

  def up
    # This is a temporary index used for the migration of Security Reports to Security Scans
    add_concurrent_index(:ci_job_artifacts,
                         [:id, :file_type, :job_id, :created_at, :updated_at],
                         name: INDEX_NAME,
                         where: PARTIAL_FILTER)
  end

  def down
    remove_concurrent_index(:ci_job_artifacts,
                            [:id, :file_type, :job_id, :created_at, :updated_at])
  end
end
