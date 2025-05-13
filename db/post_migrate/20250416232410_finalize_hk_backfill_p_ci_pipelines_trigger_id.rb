# frozen_string_literal: true

class FinalizeHkBackfillPCiPipelinesTriggerId < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  TABLE = :ci_trigger_requests
  PRIMARY_KEY = :id

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPCiPipelinesTriggerId',
      table_name: TABLE,
      column_name: PRIMARY_KEY,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
