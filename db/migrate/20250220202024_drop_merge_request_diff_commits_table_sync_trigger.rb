# frozen_string_literal: true

class DropMergeRequestDiffCommitsTableSyncTrigger < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '17.10'

  TABLE_NAME = 'merge_request_diff_commits'
  PARTITIONED_TABLE_NAME = 'merge_request_diff_commits_b5377a7a34'

  def up
    drop_trigger_to_sync_tables(TABLE_NAME)
  end

  def down
    create_trigger_to_sync_tables(TABLE_NAME, PARTITIONED_TABLE_NAME, %w[merge_request_diff_id relative_order])
  end
end
