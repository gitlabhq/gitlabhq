# frozen_string_literal: true

class CreatePartitionedMergeRequestDiffCommitsCopy < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.10'
  disable_ddl_transaction!

  def up
    partition_table_by_int_range(
      'merge_request_diff_commits',
      'merge_request_diff_id',
      partition_size: 200_000_000,
      primary_key: %w[merge_request_diff_id relative_order]
    )
  end

  def down
    drop_partitioned_table_for('merge_request_diff_commits')
  end
end
