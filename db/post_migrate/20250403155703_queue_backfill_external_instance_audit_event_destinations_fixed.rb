# frozen_string_literal: true

class QueueBackfillExternalInstanceAuditEventDestinationsFixed < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  ORIGINAL_MIGRATION = "BackfillExternalInstanceAuditEventDestinations"
  MIGRATION = "BackfillExternalInstanceAuditEventDestinationsFixed"
  BATCH_SIZE = 100
  SUB_BATCH_SIZE = 10

  def up
    # no-op because there was a bug in the migration
    # replaced by QueueFixIncompleteExternalAuditDestinations
  end

  def down; end
end
