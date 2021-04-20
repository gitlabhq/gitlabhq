# frozen_string_literal: true

class MigrateLicenseManagementArtifactsToLicenseScanning < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  LICENSE_MANAGEMENT_FILE_TYPE = 10
  LICENSE_SCANNING_FILE_TYPE = 101

  disable_ddl_transaction!

  class JobArtifact < ActiveRecord::Base
    include EachBatch

    self.table_name = 'ci_job_artifacts'
  end

  # We're updating file_type of ci artifacts from license_management to license_scanning
  # But before that we need to delete "rogue" artifacts for CI builds that have associated with them
  # both license_scanning and license_management artifacts. It's an edge case and usually, we don't have
  # such builds in the database.
  def up
    return unless Gitlab.ee?

    JobArtifact
      .where("file_type = 10 OR file_type = 101")
      .each_batch(column: :job_id, of: 1000) do |relation|
      min, max = relation.pluck('MIN(job_id)', 'MAX(job_id)').flatten

      ActiveRecord::Base.connection.execute <<~SQL
        WITH ci_job_artifacts_with_row_number as #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
          SELECT job_id, id, ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY id ASC) as row_number
          FROM ci_job_artifacts
          WHERE (file_type = #{LICENSE_SCANNING_FILE_TYPE} OR file_type = #{LICENSE_MANAGEMENT_FILE_TYPE})
          AND job_id >= #{Integer(min)} AND job_id < #{Integer(max)}
        )
        DELETE FROM ci_job_artifacts
        WHERE ci_job_artifacts.id IN (SELECT id from ci_job_artifacts_with_row_number WHERE ci_job_artifacts_with_row_number.row_number > 1)
      SQL
    end

    JobArtifact.where(file_type: LICENSE_MANAGEMENT_FILE_TYPE).each_batch(column: :job_id, of: 1000) do |relation|
      relation.update_all(file_type: LICENSE_SCANNING_FILE_TYPE)
    end
  end

  def down
    # no-op
    # we're deleting duplicating artifacts and updating file_type for license_management artifacts
  end
end
