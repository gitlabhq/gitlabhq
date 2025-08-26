# frozen_string_literal: true

class QueueBackfillDeploymentMergeRequestsForBigintConversion < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.4'

  TABLE = :deployment_merge_requests
  MIGRATION = "BackfillDeploymentMergeRequestsForBigintConversion"
  STRATEGY = 'PrimaryKeyBatchingStrategy'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 200

  def up
    return unless columns_to_backfill_exist?

    (max_id, max_order) = define_batchable_model(TABLE)
      .order(deployment_id: :desc, merge_request_id: :desc)
      .pick(:deployment_id, :merge_request_id)

    max_id ||= 0
    max_order ||= 0

    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      gitlab_schema: :gitlab_main_org,
      job_class_name: MIGRATION,
      job_arguments: [
        %i[deployment_id merge_request_id environment_id],
        %i[deployment_id_convert_to_bigint merge_request_id_convert_to_bigint environment_id_convert_to_bigint]
      ],
      table_name: TABLE,
      column_name: :deployment_id,
      min_cursor: [0, 0],
      max_cursor: [max_id, max_order],
      interval: DELAY_INTERVAL,
      pause_ms: 100,
      batch_class_name: STRATEGY,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      status_event: :execute
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      TABLE,
      :deployment_id,
      [
        %i[deployment_id merge_request_id environment_id],
        %i[deployment_id_convert_to_bigint merge_request_id_convert_to_bigint environment_id_convert_to_bigint]
      ]
    )
  end

  private

  # If we are on a newer installation where the columns are
  # already `bigint`, the previous migration will not have
  # added any new columns.
  def columns_to_backfill_exist?
    columns(TABLE).any? { |column| column.name.ends_with?('_id_convert_to_bigint') }
  end
end
