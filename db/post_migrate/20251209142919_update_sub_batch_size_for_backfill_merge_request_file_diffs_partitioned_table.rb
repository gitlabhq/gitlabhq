# frozen_string_literal: true

class UpdateSubBatchSizeForBackfillMergeRequestFileDiffsPartitionedTable < Gitlab::Database::Migration[2.3]
  milestone '18.8'

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

    return unless migration

    # Update the sub_batch_size to 2500
    updates = { sub_batch_size: 2500 }

    # Update batch_size to 50000 if it's not already larger
    updates[:batch_size] = 50000 if migration.batch_size < 50000

    migration.update!(updates)
  end

  def down
    # Find the batched background migration
    migration = Gitlab::Database::BackgroundMigration::BatchedMigration
                  .for_configuration(
                    :gitlab_main_org,
                    'BackfillMergeRequestFileDiffsPartitionedTable',
                    :merge_request_diff_files,
                    :merge_request_diff_id,
                    [:merge_request_diff_files_99208b8fac, :merge_request_diff_id, :relative_order]
                  ).first

    return unless migration

    # Revert the sub_batch_size to 200 and leave batch_size where optimizer has it
    migration.update!(sub_batch_size: 200)
  end
end
