# frozen_string_literal: true

class CleanupBackfillDraftStatusesOnMergeRequests < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  MIGRATION = 'BackfillDraftStatusOnMergeRequests'

  def up
    finalize_background_migration(MIGRATION)
  end

  def down
    # no-op
  end
end
