# frozen_string_literal: true

class AddIndexForLicenseComplianceArtifacts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_job_artifacts_on_license_compliance_file_types'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_job_artifacts, [:job_id, :file_type], where: 'file_type = 10 OR file_type = 101', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_job_artifacts, name: INDEX_NAME
  end
end
