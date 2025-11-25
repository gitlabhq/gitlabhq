# frozen_string_literal: true

class CleanupBackfillLicensesOutsideSpdxCatalogue < Gitlab::Database::Migration[2.3]
  MIGRATION = "BackfillLicensesOutsideSpdxCatalogue"

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.7'

  def up
    delete_batched_background_migration(MIGRATION, :software_license_policies, :id, [])
  end

  def down; end
end
