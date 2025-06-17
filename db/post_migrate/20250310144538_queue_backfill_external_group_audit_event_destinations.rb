# frozen_string_literal: true

class QueueBackfillExternalGroupAuditEventDestinations < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillExternalGroupAuditEventDestinations"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    # no-op because there was a bug in the original migration (double JSON encoding),
    # which has been fixed by QueueFixIncompleteInstanceExternalAuditDestinations
  end

  def down; end
end
