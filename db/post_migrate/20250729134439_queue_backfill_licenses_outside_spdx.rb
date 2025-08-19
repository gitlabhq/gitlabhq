# frozen_string_literal: true

class QueueBackfillLicensesOutsideSpdx < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillLicensesOutsideSpdx"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :software_license_policies,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :software_license_policies, :id, [])
  end
end
