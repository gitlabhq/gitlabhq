# frozen_string_literal: true

class QueueBackfillIssueAssigneesNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillIssueAssigneesNamespaceId"
  STRATEGY = 'PrimaryKeyBatchingStrategy'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    (max_id, max_order) = define_batchable_model('issue_assignees')
                            .order(issue_id: :desc, user_id: :desc)
                            .pick(:issue_id, :user_id)

    max_id ||= 0
    max_order ||= 0

    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      gitlab_schema: :gitlab_main_org,
      job_class_name: MIGRATION,
      job_arguments: [
        :namespace_id,
        :issues,
        :namespace_id,
        :issue_id
      ],
      table_name: :issue_assignees,
      column_name: :issue_id,
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
      :issue_assignees,
      :issue_id,
      [
        :namespace_id,
        :issues,
        :namespace_id,
        :issue_id
      ]
    )
  end
end
