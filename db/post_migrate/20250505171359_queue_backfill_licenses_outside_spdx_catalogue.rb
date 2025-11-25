# frozen_string_literal: true

class QueueBackfillLicensesOutsideSpdxCatalogue < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillLicensesOutsideSpdxCatalogue"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  # This migration is already finalized and we are removing the software_licenses table.
  def up; end

  def down; end
end
