# frozen_string_literal: true

class QueueBackfillAgentTypeOnDuoWorkflowSessionArtifacts < Gitlab::Database::Migration[2.3]
  milestone '19.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillAgentTypeOnDuoWorkflowSessionArtifacts"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :duo_workflow_session_artifacts,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :duo_workflow_session_artifacts, :id, [])
  end
end
