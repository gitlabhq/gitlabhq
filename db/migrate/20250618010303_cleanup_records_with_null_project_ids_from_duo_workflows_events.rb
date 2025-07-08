# frozen_string_literal: true

class CleanupRecordsWithNullProjectIdsFromDuoWorkflowsEvents < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.2'

  BATCH_SIZE = 1000

  class WorkflowEvent < MigrationRecord
    include EachBatch

    self.table_name = 'duo_workflows_events'
  end

  def up
    # no-op - this migration is required to allow a rollback of `RemoveNotNullConstraintFromDuoWorkflowsEventsProjectId`
  end

  def down
    WorkflowEvent.each_batch(of: BATCH_SIZE) do |relation|
      relation
        .where(project_id: nil)
        .delete_all
    end
  end
end
