# frozen_string_literal: true

class QueueBackfillSoftwareLicensePolicies < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillSoftwareLicensePolicies"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  # This migration is already finalized and we are removing the software_licenses table.
  def up; end

  def down; end
end
