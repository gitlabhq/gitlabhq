# frozen_string_literal: true

class CleanUpFixMergeRequestDiffCommitUsers < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  MIGRATION_CLASS = 'FixMergeRequestDiffCommitUsers'

  def up
    finalize_background_migration(MIGRATION_CLASS)
  end

  def down
    # no-op
  end
end
