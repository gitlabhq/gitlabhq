# frozen_string_literal: true

class CleanupOrphanSoftwareLicenses < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class SoftwareLicense < MigrationRecord
    self.table_name = 'software_licenses'
  end

  class SoftwareLicensePolicy < MigrationRecord
    self.table_name = 'software_license_policies'
  end

  def up
    SoftwareLicense
      .where(spdx_identifier: nil)
      .where.not(
        id: SoftwareLicensePolicy.select(:software_license_id)
      ).delete_all
  end

  def down
    # NO-OP
  end
end
