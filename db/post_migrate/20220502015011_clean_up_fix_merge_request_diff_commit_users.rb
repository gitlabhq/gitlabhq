# frozen_string_literal: true

class CleanUpFixMergeRequestDiffCommitUsers < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION_CLASS = 'FixMergeRequestDiffCommitUsers'

  def up
    finalize_background_migration(MIGRATION_CLASS)
  end

  def down
    # no-op
  end
end
