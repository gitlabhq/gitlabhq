# frozen_string_literal: true

class RemoveExistingWorkItemTypeBackfillMigrations < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  JOB_CLASS_NAME = 'BackfillWorkItemTypeIdForIssues'

  class BatchedMigration < MigrationRecord
    self.table_name = 'batched_background_migrations'
  end

  def up
    # cleaning up so we can remove a custom batching strategy that is no longer necessary
    # some environments might already have this background migrations scheduled and probably completed
    BatchedMigration.where(job_class_name: JOB_CLASS_NAME).delete_all
  end

  def down
    # no-op
    # we will reschedule this migration in the future, no need to add back here
  end
end
