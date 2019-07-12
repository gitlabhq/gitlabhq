# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateRemainingMergeRequestAssignees < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10_000
  MIGRATION = 'PopulateMergeRequestAssigneesTable'

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal(MIGRATION)

    Gitlab::BackgroundMigration::PopulateMergeRequestAssigneesTable.new.perform_all_sync(batch_size: BATCH_SIZE)
  end
end
