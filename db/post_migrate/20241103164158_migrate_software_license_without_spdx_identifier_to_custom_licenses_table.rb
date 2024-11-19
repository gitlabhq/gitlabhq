# frozen_string_literal: true

class MigrateSoftwareLicenseWithoutSpdxIdentifierToCustomLicensesTable < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 100

  def up
    each_batch_range('software_license_policies', of: BATCH_SIZE) do |min, max|
      execute <<~SQL
        INSERT INTO custom_software_licenses (name, project_id)
        SELECT
          name,
          project_id
      FROM
          software_license_policies
          INNER JOIN software_licenses ON (software_licenses.id = software_license_policies.software_license_id)
      WHERE
          software_licenses.spdx_identifier IS NULL
          AND software_license_policies.id BETWEEN #{min} AND #{max}
      ON CONFLICT DO NOTHING
      SQL
    end
  end

  def down
    # no-op
  end
end
