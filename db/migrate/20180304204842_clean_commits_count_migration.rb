class CleanCommitsCountMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal('AddMergeRequestDiffCommitsCount')
  end

  def down
  end
end
