# frozen_string_literal: true

class FinalizeBackfillPushEventPayloadsShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '18.6'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPushEventPayloadsProjectId',
      table_name: :push_event_payloads,
      column_name: :event_id,
      job_arguments: [
        :project_id,
        :events,
        :project_id,
        :event_id
      ],
      finalize: true
    )
  end

  def down; end
end
