# frozen_string_literal: true

class FixTotalTupleCountForBackfillMergeRequestFileDiffsPartitionedTable < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    # Find the batched background migration
    migration = Gitlab::Database::BackgroundMigration::BatchedMigration
      .for_configuration(
        :gitlab_main_org,
        'BackfillMergeRequestFileDiffsPartitionedTable',
        :merge_request_diff_files,
        :merge_request_diff_id,
        [:merge_request_diff_files_99208b8fac, :merge_request_diff_id, :relative_order]
      ).first

    return unless migration # Fresh installations between the BBM enqueue and this one will be missing the BBM row

    # Calculate the total_tuple_count using PgClass
    total_tuple_count = Gitlab::Database::PgClass.for_table(:merge_request_diff_files)&.cardinality_estimate

    # Update the migration with the correct total_tuple_count
    migration.update!(total_tuple_count: total_tuple_count) if total_tuple_count
  end

  def down
    # No-op: We don't want to remove the total_tuple_count
  end
end
