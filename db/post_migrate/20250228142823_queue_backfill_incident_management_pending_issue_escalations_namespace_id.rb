# frozen_string_literal: true

class QueueBackfillIncidentManagementPendingIssueEscalationsNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillIncidentManagementPendingIssueEscalationsNamespaceId"
  STRATEGY = 'PrimaryKeyBatchingStrategy'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    (max_id, max_order) = define_batchable_model('incident_management_pending_issue_escalations')
                            .order(id: :desc, process_at: :desc)
                            .pick(:id, :process_at)

    max_id ||= 0
    max_order ||= Time.current.to_s

    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      gitlab_schema: :gitlab_main_org,
      job_class_name: MIGRATION,
      job_arguments: [
        :namespace_id,
        :issues,
        :namespace_id,
        :issue_id
      ],
      table_name: :incident_management_pending_issue_escalations,
      column_name: :id,
      min_cursor: [0, 2.months.ago.to_s],
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
      :incident_management_pending_issue_escalations,
      :id,
      [
        :namespace_id,
        :issues,
        :namespace_id,
        :issue_id
      ]
    )
  end
end
