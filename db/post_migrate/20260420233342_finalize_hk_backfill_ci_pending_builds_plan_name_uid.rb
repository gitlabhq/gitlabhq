# frozen_string_literal: true

class FinalizeHkBackfillCiPendingBuildsPlanNameUid < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillCiPendingBuildsPlanNameUid',
      table_name: :ci_pending_builds,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
