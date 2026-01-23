# frozen_string_literal: true

class FinalizeUserAgentDetailsOrganizationIdBackfill < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'BackfillUserAgentDetailsOrganizationId'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :user_agent_details,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
