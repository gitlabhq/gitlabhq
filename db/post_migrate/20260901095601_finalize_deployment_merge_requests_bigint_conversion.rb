# frozen_string_literal: true

class FinalizeDeploymentMergeRequestsBigintConversion < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '19.4'

  # The backfill was queued with a cursor-based job class rather than
  # CopyColumnUsingBackgroundMigrationJob, so the bigint conversion helper
  # cannot locate it and we ensure the migration finished directly.
  MIGRATION = 'BackfillDeploymentMergeRequestsForBigintConversion'
  JOB_ARGUMENTS = [
    %w[deployment_id merge_request_id environment_id],
    %w[deployment_id_convert_to_bigint merge_request_id_convert_to_bigint environment_id_convert_to_bigint]
  ].freeze

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :deployment_merge_requests,
      column_name: :deployment_id,
      job_arguments: JOB_ARGUMENTS,
      finalize: true
    )
  end

  def down
    # no-op
  end
end
